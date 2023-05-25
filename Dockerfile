FROM odoo:11
USER root

RUN pip3 install py3o.template py3o.formats PyPDF2 openpyxl # py3o required
USER odoo
