"""
Management command para BORRAR todos los pixeles/sesiones/logs existentes
y volver a sembrar las imágenes fundacionales desde cero.

Uso:
    python manage.py reset_and_seed

Por defecto:
    - Borra TODOS los Pixel, PixelPurchaseSession y PixelViewLog
    - Borra los archivos físicos en media/pixels/
    - Invalida el caché de grid_status
    - Siembra 1.jpg ... 7.jpg desde backend/seed_images/ en (0,0) a (6,0)

¡CUIDADO! Esto borra TODO, incluidos pixeles comprados de verdad.
Úsalo solo en desarrollo.
"""
import os
import shutil
from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.core.files import File
from django.utils import timezone

from pixels.models import Pixel, PixelPurchaseSession, PixelViewLog
from pixels.services.grid_manager import GridManager


class Command(BaseCommand):
    help = 'Borra todos los pixeles existentes y vuelve a sembrar las imágenes desde cero'

    def add_arguments(self, parser):
        parser.add_argument(
            '--folder',
            type=str,
            default=str(settings.BASE_DIR / 'seed_images'),
            help='Carpeta donde están las imágenes (default: backend/seed_images)',
        )
        parser.add_argument(
            '--files',
            type=str,
            default='1.jpg,2.jpg,3.jpg,4.jpg,5.jpg,6.jpg,7.jpg',
            help='Lista de archivos separados por coma',
        )
        parser.add_argument(
            '--owner-email',
            type=str,
            default='founder@everwall.com',
        )
        parser.add_argument(
            '--owner-name',
            type=str,
            default='Everwall',
        )
        parser.add_argument(
            '--start-x',
            type=int,
            default=0,
        )
        parser.add_argument(
            '--y',
            type=int,
            default=0,
        )
        parser.add_argument(
            '--keep-media-files',
            action='store_true',
            help='No borrar los archivos físicos en media/pixels/ (solo borra registros de la DB)',
        )
        parser.add_argument(
            '--yes',
            action='store_true',
            help='Confirma el borrado sin preguntar (necesario para correr sin input interactivo)',
        )

    def handle(self, *args, **options):
        folder = options['folder']
        owner_email = options['owner_email']
        owner_name = options['owner_name']
        start_x = options['start_x']
        y = options['y']
        keep_media_files = options['keep_media_files']
        confirmed = options['yes']

        filenames = [f.strip() for f in options['files'].split(',') if f.strip()]
        if not filenames:
            raise CommandError('No se especificaron archivos válidos en --files')

        if not os.path.isdir(folder):
            raise CommandError(f'No existe la carpeta: {folder}')

        pixel_count = Pixel.objects.count()
        session_count = PixelPurchaseSession.objects.count()
        log_count = PixelViewLog.objects.count()

        self.stdout.write(self.style.WARNING('=== RESET COMPLETO DE PIXELES ==='))
        self.stdout.write(
            f'Se van a borrar: {pixel_count} pixeles, {session_count} sesiones, {log_count} logs de vistas'
        )

        if not confirmed:
            answer = input('¿Confirmas el borrado? Escribe "SI" para continuar: ')
            if answer.strip().upper() != 'SI':
                self.stdout.write(self.style.ERROR('Cancelado, no se borró nada'))
                return

        # 1. Borrar registros de la base de datos
        PixelViewLog.objects.all().delete()
        PixelPurchaseSession.objects.all().delete()
        Pixel.objects.all().delete()
        self.stdout.write(self.style.SUCCESS('  -> Registros de base de datos eliminados'))

        # 2. Borrar archivos físicos en media/pixels/
        if not keep_media_files:
            pixels_media_dir = os.path.join(settings.MEDIA_ROOT, 'pixels')
            if os.path.isdir(pixels_media_dir):
                shutil.rmtree(pixels_media_dir)
                self.stdout.write(self.style.SUCCESS(f'  -> Carpeta {pixels_media_dir} eliminada'))
            else:
                self.stdout.write('  -> No existía carpeta media/pixels/, nada que borrar')

        # 3. Invalidar caché
        GridManager.invalidate_cache()
        self.stdout.write(self.style.SUCCESS('  -> Caché de grid_status invalidado'))

        # 4. Volver a sembrar
        self.stdout.write(self.style.SUCCESS(f'\n=== Sembrando {len(filenames)} imágenes desde {folder} ==='))
        created_count = 0

        for idx, filename in enumerate(filenames):
            file_path = os.path.join(folder, filename)
            x = start_x + idx

            if not os.path.isfile(file_path):
                self.stdout.write(self.style.ERROR(f'  [SKIP] No se encontró {file_path}'))
                continue

            with open(file_path, 'rb') as f:
                pixel = Pixel(
                    x=x,
                    y=y,
                    owner=None,
                    owner_name=owner_name,
                    owner_email=owner_email,
                    owner_message='',
                    image_filename=filename,
                    status='sold',
                    moderation_status='approved',
                    payment_status='completed',
                    purchased_at=timezone.now(),
                )
                pixel.main_image.save(filename, File(f), save=False)
                pixel.save()

            created_count += 1
            self.stdout.write(
                self.style.SUCCESS(f'  -> Creado pixel ({x}, {y}) código {pixel.display_code} con {filename}')
            )

        # 5. Invalidar caché de nuevo (por si quedó algo cacheado durante el proceso)
        GridManager.invalidate_cache()

        self.stdout.write(self.style.SUCCESS(f'\n=== Listo: {created_count} pixeles creados desde cero ==='))