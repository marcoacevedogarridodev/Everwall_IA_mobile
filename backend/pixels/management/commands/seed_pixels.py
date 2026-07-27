"""
Management command para sembrar los primeros pixeles "fundacionales" del proyecto,
sin pasar por el flujo de compra (Stripe / frontend).

Uso:
    python manage.py seed_pixels

Por defecto busca las imágenes en backend/seed_images/1.jpg, 2.jpg, 3.jpg, 4.jpg
y las coloca en las coordenadas (0,0), (1,0), (2,0), (3,0).

Puedes personalizar carpeta y coordenadas con argumentos, ver --help.
"""
import os
from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.core.files import File
from django.utils import timezone

from pixels.models import Pixel


class Command(BaseCommand):
    help = 'Crea pixeles fundacionales a partir de imágenes locales, sin pasar por compra/Stripe'

    def add_arguments(self, parser):
        parser.add_argument(
            '--folder',
            type=str,
            default=str(settings.BASE_DIR / 'seed_images'),
            help='Carpeta donde están las imágenes 1.jpg, 2.jpg, 3.jpg, 4.jpg (default: backend/seed_images)',
        )
        parser.add_argument(
            '--owner-email',
            type=str,
            default='founder@everwall.com',
            help='Email que se asignará a estos pixeles (default: founder@everwall.com)',
        )
        parser.add_argument(
            '--owner-name',
            type=str,
            default='Everwall',
            help='Nombre del dueño mostrado en el pixel',
        )
        parser.add_argument(
            '--start-x',
            type=int,
            default=0,
            help='Coordenada X inicial (default: 0)',
        )
        parser.add_argument(
            '--y',
            type=int,
            default=0,
            help='Coordenada Y para todos los pixeles (default: 0)',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Muestra qué se crearía sin guardar nada',
        )

    def handle(self, *args, **options):
        folder = options['folder']
        owner_email = options['owner_email']
        owner_name = options['owner_name']
        start_x = options['start_x']
        y = options['y']
        dry_run = options['dry_run']

        filenames = ['1.jpg', '2.jpg', '3.jpg', '4.jpg']

        if not os.path.isdir(folder):
            raise CommandError(f'No existe la carpeta: {folder}')

        self.stdout.write(self.style.SUCCESS(f'=== Sembrando pixeles desde {folder} ==='))
        if dry_run:
            self.stdout.write(self.style.WARNING('MODO DRY-RUN: no se guardará nada'))

        created_count = 0

        for idx, filename in enumerate(filenames):
            file_path = os.path.join(folder, filename)
            x = start_x + idx

            if not os.path.isfile(file_path):
                self.stdout.write(self.style.ERROR(f'  [SKIP] No se encontró {file_path}'))
                continue

            # Verificar que el pixel no exista ya (unique_together x,y)
            if Pixel.objects.filter(x=x, y=y).exists():
                self.stdout.write(
                    self.style.WARNING(f'  [SKIP] Ya existe un pixel en ({x}, {y}), se omite {filename}')
                )
                continue

            if dry_run:
                self.stdout.write(f'  [DRY-RUN] Crearía pixel ({x}, {y}) con {filename}')
                continue

            with open(file_path, 'rb') as f:
                pixel = Pixel(
                    x=x,
                    y=y,
                    owner=None,  # pixel fundacional, sin usuario asociado
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
                self.style.SUCCESS(f'  -> Creado pixel ({x}, {y}) código {pixel.display_code}')
            )

        if not dry_run:
            self.stdout.write(self.style.SUCCESS(f'\n=== Listo: {created_count} pixeles creados ==='))
        else:
            self.stdout.write(self.style.WARNING('\n=== Dry-run finalizado, nada fue guardado ==='))