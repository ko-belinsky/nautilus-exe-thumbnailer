# Makefile for EXE thumbnailer installation
.PHONY: install uninstall

INSTALL_DIR = /usr/local/bin
THUMBNAILER_DIR = /usr/share/thumbnailers
SCRIPT_NAME = exe-thumbnailer
THUMBNAILER_NAME = exe.thumbnailer

install:
	@echo "Проверка зависимостей..."
	@if ! command -v wrestool >/dev/null 2>&1 || ! command -v convert >/dev/null 2>&1; then \
		echo "Установка icoutils и imagemagick..."; \
		su -c 'apt-get install -y icoutils imagemagick'; \
	else \
		echo "Все зависимости уже установлены."; \
	fi
	
	@read -p "Хотите указать текущий цвет фона Nautilus, для заливки \"шахматного фона\"? [y/N] " choice; \
	if [ "$$choice" = "y" ] || [ "$$choice" = "Y" ]; then \
		read -p "Введите цвет в формате #xxxxxx: " bg_color; \
		bg_line="bg_color=\"$$bg_color\"  # Цвет подложки"; \
	else \
		bg_line="bg_color=\"none\"  # Прозрачный фон"; \
	fi; \
	echo "#!/bin/bash\n\
input=\"\$$1\"\n\
output=\"\$$2\"\n\
temp_dir=\"/tmp/exe-thumbnailer-\$$\"\n\
$$bg_line\n\
\n\
mkdir -p \"\$$temp_dir\"\n\
cd \"\$$temp_dir\" || exit 1\n\
\n\
wrestool -x -t 14 \"\$$input\" -o \"temp.ico\" >/dev/null 2>&1\n\
\n\
if [ -f \"temp.ico\" ]; then\n\
    icotool -x \"temp.ico\" >/dev/null 2>&1\n\
    largest_png=\$$(find . -name \"temp_*.png\" -exec du -b {} + | sort -nr | head -n1 | cut -f2)\n\
\n\
    if [ -f \"\$$largest_png\" ]; then\n\
        if [ \"\$$bg_color\" = \"none\" ]; then\n\
            convert \"\$$largest_png\" \\\n\
                -resize 256x256 \\\n\
                -unsharp 0.5x0.5+0.5+0.008 \\\n\
                \"\$$output\" >/dev/null 2>&1\n\
        else\n\
            convert -size 256x256 \"xc:\$$bg_color\" \\\n\
                \"\$$largest_png\" -resize 256x256 -composite \\\n\
                -unsharp 0.5x0.5+0.5+0.008 \\\n\
                \"\$$output\" >/dev/null 2>&1\n\
        fi\n\
    fi\n\
fi\n\
\n\
if [ ! -f \"\$$output\" ]; then\n\
    if [ \"\$$bg_color\" = \"none\" ]; then\n\
        convert \"/usr/share/icons/Adwaita/256x256/mimetypes/application-x-executable.png\" \\\n\
            -resize 256x256 \"\$$output\" >/dev/null 2>&1\n\
    else\n\
        convert -size 256x256 \"xc:\$$bg_color\" \\\n\
            \"/usr/share/icons/Adwaita/256x256/mimetypes/application-x-executable.png\" \\\n\
            -resize 224x224 -gravity center -composite \\\n\
            \"\$$output\" >/dev/null 2>&1\n\
    fi\n\
fi\n\
\n\
rm -rf \"\$$temp_dir\"\n\
exit 0" > script.tmp; \
	echo "[Thumbnailer Entry]\n\
Exec=$(INSTALL_DIR)/$(SCRIPT_NAME) %i %o\n\
MimeType=application/x-dosexec;application/x-ms-dos-executable;application/vnd.microsoft.portable-executable" > thumbnailer.tmp; \
	echo "Копирование файлов..."; \
	su -c "cp script.tmp $(INSTALL_DIR)/$(SCRIPT_NAME) && \
	chmod +x $(INSTALL_DIR)/$(SCRIPT_NAME) && \
	cp thumbnailer.tmp $(THUMBNAILER_DIR)/$(THUMBNAILER_NAME)"; \
	rm -f script.tmp thumbnailer.tmp; \
	echo "Очистка кэша превью..."; \
	pkill nautilus || true; \
	rm -rf ~/.cache/thumbnails/*; \
	echo "Установка завершена. Перезапустите Nautilus."

uninstall:
	@echo "Удаление EXE thumbnailer..."
	@su -c "rm -f $(INSTALL_DIR)/$(SCRIPT_NAME) $(THUMBNAILER_DIR)/$(THUMBNAILER_NAME)"
	@echo "Удаление завершено. Не забудьте очистить кэш: rm -rf ~/.cache/thumbnails/*"
