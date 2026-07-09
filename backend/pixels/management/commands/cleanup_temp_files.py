"""
Management command to clean up temporary files and expired purchase sessions
Run with: python manage.py cleanup_temp_files
"""
import os
import logging
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.core.files.storage import default_storage
from pixels.models import PixelPurchaseSession

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Limpia archivos temporales huérfanos y sesiones de compra expiradas'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Muestra qué sería eliminado sin hacer cambios reales',
        )
        parser.add_argument(
            '--temp-hours',
            type=int,
            default=24,
            help='Edad mínima de archivos temp en horas (default: 24)',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        temp_hours = options['temp_hours']
        
        self.stdout.write(self.style.SUCCESS('=== Iniciando cleanup ==='))
        if dry_run:
            self.stdout.write(self.style.WARNING('MODO DRY-RUN: No se eliminarán archivos'))
        
        # Limpiar sesiones expiradas
        self._cleanup_expired_sessions(dry_run)
        
        # Limpiar archivos temporales huérfanos
        self._cleanup_orphan_temp_files(dry_run, temp_hours)
        
        self.stdout.write(self.style.SUCCESS('=== Cleanup completado ==='))

    def _cleanup_expired_sessions(self, dry_run=False):
        """Elimina PixelPurchaseSession que han expirado"""
        self.stdout.write('\n[SESSIONS] Limpiando sesiones expiradas...')
        
        now = timezone.now()
        expired_sessions = PixelPurchaseSession.objects.filter(
            expires_at__lt=now,
            is_completed=False
        )
        
        count = expired_sessions.count()
        
        if count == 0:
            self.stdout.write('  -> No hay sesiones expiradas')
            return
        
        session_ids = list(expired_sessions.values_list('session_id', flat=True))
        
        if dry_run:
            self.stdout.write(self.style.WARNING(f'  [DRY-RUN] Se eliminarían {count} sesiones:'))
            for sid in session_ids[:5]:
                self.stdout.write(f'    - {sid}')
            if len(session_ids) > 5:
                self.stdout.write(f'    ... y {len(session_ids) - 5} más')
        else:
            expired_sessions.delete()
            self.stdout.write(self.style.SUCCESS(f'  -> Eliminadas {count} sesiones expiradas'))
            logger.info(f'Cleaned up {count} expired purchase sessions: {session_ids}')

    def _cleanup_orphan_temp_files(self, dry_run=False, temp_hours=24):
        """
        Elimina archivos temporales que:
        1. No están asociados a ninguna sesión incompleta
        2. Tienen más de temp_hours de antigüedad
        """
        self.stdout.write('\n[FILES] Limpiando archivos temporales huérfanos...')
        
        # Obtener todas las sesiones incompletas activas
        active_sessions = PixelPurchaseSession.objects.filter(
            is_completed=False,
            expires_at__gte=timezone.now()
        )
        
        # Recopilar todos los archivos temporales en uso
        active_temp_files = set()
        for session in active_sessions:
            active_temp_files.update(session.images_data or [])
        
        # Buscar archivos en temp/
        temp_dir = 'temp'
        if not default_storage.exists(temp_dir):
            self.stdout.write('  -> No existe directorio temp/')
            return
        
        # Listar archivos en temp/
        try:
            _, file_names = default_storage.listdir(temp_dir)
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'  ERROR al listar temp/: {str(e)}'))
            logger.error(f'Error listing temp directory: {str(e)}')
            return
        
        cutoff_time = timezone.now() - timedelta(hours=temp_hours)
        files_to_delete = []
        
        for file_name in file_names:
            file_path = f'{temp_dir}/{file_name}'
            
            # Saltar si está en uso
            if file_path in active_temp_files:
                continue
            
            # Verificar antigüedad (usar mtime si está disponible)
            try:
                file_stat = default_storage.get_created_time(file_path)
                if file_stat < cutoff_time:
                    files_to_delete.append(file_path)
            except Exception:
                # Si no podemos obtener mtime, lo eliminamos de todas formas
                # (es probable que sea antiguo si está huérfano)
                files_to_delete.append(file_path)
        
        if len(files_to_delete) == 0:
            self.stdout.write('  -> No hay archivos temporales huérfanos')
            return
        
        if dry_run:
            self.stdout.write(
                self.style.WARNING(
                    f'  [DRY-RUN] Se eliminarían {len(files_to_delete)} archivos:'
                )
            )
            for fp in files_to_delete[:5]:
                self.stdout.write(f'    - {fp}')
            if len(files_to_delete) > 5:
                self.stdout.write(f'    ... y {len(files_to_delete) - 5} más')
        else:
            deleted_count = 0
            failed_count = 0
            
            for file_path in files_to_delete:
                try:
                    if default_storage.exists(file_path):
                        default_storage.delete(file_path)
                        deleted_count += 1
                except Exception as e:
                    logger.warning(f'Failed to delete {file_path}: {str(e)}')
                    failed_count += 1
            
            self.stdout.write(
                self.style.SUCCESS(
                    f'  -> Eliminados {deleted_count}/{len(files_to_delete)} archivos temporales'
                )
            )
            
            if failed_count > 0:
                self.stdout.write(
                    self.style.WARNING(f'  [WARNING] {failed_count} archivos no pudieron eliminarse')
                )
                logger.warning(f'Failed to delete {failed_count} temp files')
            else:
                logger.info(f'Cleaned up {deleted_count} orphaned temp files')
