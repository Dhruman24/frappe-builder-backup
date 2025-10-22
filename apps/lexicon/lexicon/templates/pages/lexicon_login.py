import frappe

def get_context(context):
    context.no_cache = 1
    # This page doesn't require any additional context
    return context
