## Convert Jupyter Notebook (.ipynb) to Python (.py) using Terminal

-- install package
$ pip install jupyter

$ pip install nbconvert

### Syntax

$ jupyter nbconvert --to OPTIONS FileName.ipynb

$ "OPTIONS", did you mean one of: asciidoc, custom, html, latex, markdown, notebook, pdf, python, rst, script, slides, webpdf?
### example
$ jupyter nbconvert --to python Notebooks/example_brightfield.ipynb



