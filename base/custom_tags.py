from django import template
from django.utils.safestring import mark_safe

register = template.Library()

@register.filter
def add_attr(value, arg):
    attrs = arg.split(',')
    tag = str(value)
    for attr in attrs:
        key, val = attr.split(':')
        tag = tag.replace('>', ' {}="{}">'.format(key, val), 1)
    return mark_safe(tag)
