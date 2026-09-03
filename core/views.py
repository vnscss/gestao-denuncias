from django.urls import reverse_lazy


class GenericCRUDMixin:
    """
    Mixin que adiciona informações úteis ao contexto (nomes singular/plural,
    URLs derivadas e opções de ação) e define a URL de sucesso padrão para as
    views de Create, Update e Delete.

    As views que herdam dele podem definir os atributos:
    - model_name_singular (ex: "Usuário")
    - model_name_plural   (ex: "Usuários")
    - template_name_suffix (usado para customizar o sufixo do template)
    - options (lista de dicts de botões personalizados; se não definida,
      usa as opções padrão de editar/deletar)
    """
    model_name_singular = "Objeto"
    model_name_plural = "Objetos"
    template_name_suffix = None
    options = None
    success_url = None

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        model_name_lower = self.model._meta.model_name

        context['model_name_singular'] = self.model_name_singular
        context['model_name_plural'] = self.model_name_plural

        context['list_url'] = f'{model_name_lower}_list'
        context['create_url'] = f'{model_name_lower}_create'
        context['update_url'] = f'{model_name_lower}_update'
        context['delete_url'] = f'{model_name_lower}_delete'
        context['detail_url'] = f'{model_name_lower}_detail'

        context['options'] = self.get_options(self.object)

        return context

    def get_success_url(self):
        if self.success_url:
            return self.success_url

        model_name_lower = self.model._meta.model_name
        return reverse_lazy(f'{model_name_lower}_list')

    def get_options(self, object):
        if self.options is not None:
            return self.options

        model_name_lower = self.model._meta.model_name
        pk = getattr(object, 'pk', None)

        return [
            {
                'label': 'Editar',
                'url': f'{model_name_lower}_update',
                'url_kwargs': {'pk': pk},
            },
            {
                'label': 'Excluir',
                'url': f'{model_name_lower}_delete',
                'url_kwargs': {'pk': pk},
            },
        ]
