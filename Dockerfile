# Capa de selección de la imagen base: En esta etapa, selecciono la imagen de Docker que servirá como punto de partida. 
# Elijo una imagen que ya incluye PHP 8.2 y Apache, lo que proporciona un entorno preconfigurado para alojar aplicaciones Laravel.

FROM php:8.2-apache

# Capa de configuración del entorno base: En esta etapa, configuro el entorno base del contenedor. Actualizo el sistema y añado 
# las dependencias esenciales, como bibliotecas de imágenes (libpng, libjpeg, libfreetype), utilidades de desarrollo (zip, git, unzip),
# extensiones de PHP (xsl, mysqli, pdo, pdo_mysql), y habilito el módulo de reescritura de URL de Apache (mod_rewrite) para traducir 
# URL's no amigables y enrutar solicitudes HTTP a controladores o rutas específicas de la futura aplicación.

RUN apt-get update && apt-get install -y libpng-dev libjpeg-dev libfreetype6-dev zip git unzip\
    libxslt-dev libxslt1-dev default-mysql-client && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install gd xsl mysqli pdo pdo_mysql && \
    a2enmod rewrite

# Capa de instalación de Composer: En esta capa, instalo Composer (herramienta fundamental para gestionar las dependencias de mis proyectos Laravel
# y otras aplicaciones PHP en el entorno del contenedor) a nivel de sistema dentro del contenedor y no afecta al sistema fuera del contenedor.

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=2.6.5

# Capa de configuración de Apache: A continuación, copio un archivo de configuración personalizado de Apache (000-default.conf) a la ubicación adecuada
# (/etc/apache2/sites-available/000-default.conf). Esto me permite personalizar la configuración de Apache según las necesidades específicas de mi proyecto Laravel.
# Esta configuración instancia apache dentro del contenedor y no afecta al sistema fuera del contenedor.

COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

# Capa de configuración del directorio de trabajo: Aquí, establezco el directorio de trabajo actual en /var/www/html, que es donde alojaré los
# archivos de mi proyecto Laravel. Esta configuración es válida solo en el contexto de mi contenedor.

WORKDIR /var/www/html

# Capa de creación del proyecto Laravel si no existe: En esta capa, verifico si ya existe un proyecto Laravel en el directorio de trabajo de
# mi contenedor (/var/www/html). Si no existe, creo un nuevo proyecto Laravel utilizando Composer con la opción --prefer-dist, lo que descarga
# el proyecto en su forma comprimida. Luego, ajusto los permisos de escritura y ejecución a todos los usuarios (propietario y grupo tendrán todos 
# los permisos) de las carpetas storage y bootstrap/cache para garantizar el funcionamiento de Laravel. Estas acciones son específicas de mi proyecto
# dentro del contenedor.

RUN if [ ! -d "/var/www/html/vendor" ]; then \
    composer create-project --prefer-dist laravel/laravel . && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache; \
fi

# Capa de instalación de paquetes y configuración de Laravel: Luego, utilizo Composer y comandos de Laravel (artisan) para instalar paquetes y configurar
# características adicionales en mi proyecto. Esto incluye la instalación de laravel/ui (para el sistema de autenticación y autorización),
# laravelcollective/html (para formularios y validaciones), y laravelcollective/security. También podré generar claves y optimizar la configuración de Laravel en
# el contexto de mi proyecto.

# RUN composer require laravel/ui:^3.0 laravel/notifications:^5.0 laravelcollective/html:^8.0 laravelcollective/security:^8.0 && \
#    php artisan ui bootstrap --auth && \
#    php artisan ui vue --auth && \
#    php artisan key:generate && \
#    php artisan config:cache

# Capa de exposición del puerto 80: Finalmente, expongo el puerto 80 de mi contenedor, lo que permite que las solicitudes HTTP lleguen al servidor web Apache
# dentro del contenedor. Esta configuración se aplica dentro de mi contenedor y es necesaria para acceder al servidor web.

EXPOSE 80