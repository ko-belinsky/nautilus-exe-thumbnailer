.PHONY: install uninstall

INSTALL_DIRS = /usr/local/bin /usr/share/thumbnailers
THUMBNAILER = exe-thumbnailer
THUMBNAILER_CONF = exe.thumbnailer
BG_COLOR = "#272727"

install:
    @echo "Проверка зависимостей..."
    @if ! command -v wrestool >/dev/null 2>&1 || ! command -v convert >/dev/null 2>&1; then \
        echo "Установка icoutils и imagemagick..."; \
        su -c 'apt-get install -y icoutils imagemagick'; \
    fi
    @echo "Создание скрипта $(THUMBNAILER)..."
    @read -p "Хотите указать текущий цвет фона Nautilus? [y/N] " choice; \
    if [ "$$choice" = "y" ] || [ "$$choice" = "Y" ]; then \
        read -p "Введите цвет в формате #xxxxxx: " color; \
        BG_COLOR="$$color"; \
    fi
    @echo "#!/bin/bash" > $(THUMBNAILER)
    @echo 'input="$$1"' >> $(THUMBNAILER)
    @echo 'output="$$2"' >> $(THUMBNAILER)
    @echo 'temp_dir="/tmp/exe-thumbnailer-$$"' >> $(THUMBNAILER)
    @echo 'bg_color=$(BG_COLOR)' >> $(THUMBNAILER)
    @echo '' >> $(THUMBNAILER)
    @echo 'mkdir -p "$$temp_dir"' >> $(THUMBNAILER)
    @echo 'cd "$$temp_dir" || exit 1' >> $(THUMBNAILER)
    @echo '' >> $(THUMBNAILER)
    @echo 'wrestool -x -t 14 "$$input" -o "temp.ico" >/dev/null 2>&1' >> $(THUMBNAILER)
    @echo '' >> $(THUMBNAILER)
    @echo 'if [ -f "temp.ico" ]; then' >> $(THUMBNAILER)
    @echo '    icotool -x "temp.ico" >/dev/null 2>&1' >> $(THUMBNAILER)
    @echo '' >> $(THUMBNAILER)
    @echo '    largest_png=$$(find . -name "temp_*.png" -exec du -b {} + | sort -nr | head -n1 | cut -f2)' >> $(THUMBNAILER)
    @echo '' >> $(THUMBNAILER)
    @echo '    if [ -f "$$largest_png" ]; then' >> $(THUMBNAILER)
    @echo '        convert -size 256x256 "xc:$$bg_color" \' >> $(THUMBNAILER)
    @echo '                "$$largest_png" -resize 256x256 -composite \' >> $(THUMBNAILER)
    @echo '                -unsharp 0.5x0.5+0.5+0.008 \' >> $(THUMBNAILER)
    @echo '                "$$output" >/dev/null 2>&1' >> $(THUMBNAILER)
    @echo '    fi' >> $(THUMBNAILER)
    @echo 'fi' >> $(THUMBNAILER)
    @echo '' >> $(THUMBNAILER)
    @echo 'if [ ! -f "$$output" ]; then' >> $(THUMBNAILER)
    @echo '    convert -size 256x256 "xc:$$bg_color" \' >> $(THUMBNAILER)
    @echo '            "/usr/share/icons/Adwaita/256x256/mimetypes/application-x-executable.png" \' >> $(THUMBNAILER)
    @echo '            -resize 224x224 -gravity center -composite \' >> $(THUMBNAILER)
    @echo '            "$$output" >/dev/null 2>&1' >> $(THUMBNAILER)
    @echo 'fi' >> $(THUMBNAILER)
    @echo '' >> $(THUMBNAILER)
    @echo 'rm -rf "$$temp_dir"' >> $(THUMBNAILER)
    @echo 'exit 0' >> $(THUMBNAILER)
    
    @echo "Создание конфигурации $(THUMBNAILER_CONF)..."
    @echo "[Thumbnailer Entry]" > $(THUMBNAILER_CONF)
    @echo "Exec=/usr/local/bin/$(THUMBNAILER) %i %o" >> $(THUMBNAILER_CONF)
    @echo "MimeType=application/x-dosexec;application/x-ms-dos-executable;application/vnd.microsoft.portable-executable" >> $(THUMBNAILER_CONF)
    
    @echo "Установка файлов..."
    @for dir in $(INSTALL_DIRS); do \
        su -c "mkdir -p $$dir"; \
    done
    @su -c "cp $(THUMBNAILER) /usr/local/bin/ && chmod +x /usr/local/bin/$(THUMBNAILER)"
    @su -c "cp $(THUMBNAILER_CONF) /usr/share/thumbnailers/"
    
    @echo "Очистка кэша..."
    @su -c "pkill nautilus && rm -rf $$HOME/.cache/thumbnails/*"
    @echo "Установка завершена!"

uninstall:
    @echo "Удаление файлов..."
    @su -c "rm -f /usr/local/bin/$(THUMBNAILER) /usr/share/thumbnailers/$(THUMBNAILER_CONF)"
    @echo "Очистка кэша..."
    @su -c "pkill nautilus && rm -rf $$HOME/.cache/thumbnails/*"
    @echo "Удаление завершено!"
