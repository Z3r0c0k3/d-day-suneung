from django.shortcuts import render

# Create your views here.

def main_page(request):
    return render(request, 'counter/main_page.html')

def page_not_found_view(request, exception):
    return render(request, 'counter/404.html', status=404)
