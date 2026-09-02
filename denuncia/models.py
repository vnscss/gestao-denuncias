import secrets

from django.db import models
from django.utils import timezone


class Denuncia(models.Model):
    titulo = models.CharField(max_length=200)
    texto = models.TextField()
    data = models.DateTimeField(auto_now_add=True)
    protocolo = models.CharField(max_length=20, unique=True, blank=True)

    def save(self, *args, **kwargs):
        if not self.protocolo:
            self.protocolo = self._gerar_protocolo()
        super().save(*args, **kwargs)

    def _gerar_protocolo(self):
        ano_mes = timezone.now().strftime('%Y%m')
        tamanho_hash = 6
        while True:
            hash = secrets.token_hex(1).upper()[:tamanho_hash]
            protocolo = f'{ano_mes}-{hash}'
            if not Denuncia.objects.filter(protocolo=protocolo).exists():
                return protocolo
            tamanho_hash += 1

    def __str__(self):
        return f'{self.protocolo} - {self.titulo}'


class Resposta(models.Model):
    denuncia = models.ForeignKey(Denuncia, on_delete=models.CASCADE, related_name='respostas')
    titulo = models.CharField(max_length=200)
    texto = models.TextField()

    def __str__(self):
        return f'Resposta para {self.denuncia.protocolo}'