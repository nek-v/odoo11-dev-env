FROM debian:buster
USER root

# Add contrib repo
RUN sed -i -e "s/ main[[:space:]]*\$/ main contrib non-free/" /etc/apt/sources.list

RUN set -x; \
        apt-get update && apt-get install -yq --no-install-recommends \
			cabextract \
            ca-certificates \
            curl \
            node-less \
            python3-pip \
            python3-setuptools \
            python3-renderpm \
            python3-wheel \
            xz-utils \
            python3-watchdog \
            git \
            gnupg \
			wget

# Install Wkhtmltox
RUN set -x; \
	wget -qO wkhtmltox.deb https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb && \
	dpkg --force-depends -i wkhtmltox.deb && \
	apt-get -yq install -f --no-install-recommends

# Install PG client
RUN set -x; \
    wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
	echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" >> /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && apt-get -y install -f --no-install-recommends postgresql-client-10

# Install Odoo
RUN set -x; \
    wget -qO - https://nightly.odoo.com/odoo.key | gpg --dearmor -o /usr/share/keyrings/odoo-archive-keyring.gpg && \
	echo 'deb [signed-by=/usr/share/keyrings/odoo-archive-keyring.gpg] https://nightly.odoo.com/11.0/nightly/deb/ ./' | \
    tee /etc/apt/sources.list.d/odoo.list && \
	apt-get update && apt-get -yq --no-install-recommends install odoo

# Install LibreOffice
RUN set -x; \
	apt-get -yq --no-install-recommends install libreoffice libreoffice-java-common default-jre

# Install fonts
RUN set -x; \
    apt-get update && \
	apt-get -yq install ttf-mscorefonts-installer && \
	mkdir ~/.fonts && \
    wget -qO- http://plasmasturm.org/code/vistafonts-installer/vistafonts-installer | bash && \
	fc-cache -v -f

# Install deps
RUN set -x; \
    pip3 install --no-cache-dir  \
        wheel \
        num2words  \
        phonenumbers  \
        py3o.template  \
        py3o.formats  \
        PyPDF2  \
        openpyxl \
        pytils

# Clear
RUN set -x; \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* wkhtmltox.deb

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./etc/odoo.conf /etc/odoo/
RUN chmod +x entrypoint.sh && \
    chown odoo /etc/odoo/odoo.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons && \
    chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
