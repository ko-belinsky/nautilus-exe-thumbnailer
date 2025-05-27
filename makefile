# Makefile для установки превью .exe в Nautilus
.PHONY: install uninstall check-deps install-script install-thumbnailer cleanup

INSTALL_DIR = /usr/local/bin
THUMBNAILER_DIR = /usr/share/thumbnailers
SCRIPT_NAME = exe-thumbnailer
THUMBNAILER_NAME = exe.thumbnailer

install: check-deps install-script install-thumbnailer cleanup
	@echo "Установка завершена успешно!"

uninstall:
	@echo "Удаление EXE thumbnailer..."
	@rm -f $(INSTALL_DIR)/$(SCRIPT_NAME)
	@rm -f $(THUMBNAILER_DIR)/$(THUMBNAILER_NAME)
	@echo "Удаление завершено. Не забудьте очистить кэш: rm -rf ~/.cache/thumbnails/*"

check-deps:
	@echo "Проверка зависимостей..."
	@if ! command -v wrestool >/dev/null 2>&1 || ! command -v convert >/dev/null 2>&1; then \
		echo "Установка icoutils и imagemagick..."; \
		su -c 'apt-get install -y icoutils imagemagick'; \
	else \
		echo "Все зависимости уже установлены."; \
	fi

install-script:
	@echo "Создание скрипта $(SCRIPT_NAME)..."
	@echo "#!/bin/bash" > $(SCRIPT_NAME)
	@echo "input=\"\$$1\"" >> $(SCRIPT_NAME)
	@echo "output=\"\$$2\"" >> $(SCRIPT_NAME)
	@echo "temp_dir=\"/tmp/exe-thumbnailer-\$$\"" >> $(SCRIPT_NAME)
	
	@read -p "Хотите указать цвет фона вместо шахматного? [y/N] " choice; \
	if [ "$$choice" = "y" ] || [ "$$choice" = "Y" ]; then \
		read -p "Введите цвет в формате #xxxxxx: " bg_color; \
		echo "bg_color=\"$$bg_color\"  # Цвет подложки" >> $(SCRIPT_NAME); \
		echo 'if [ "$$bg_color" != "none" ]; then' >> $(SCRIPT_NAME); \
		echo '  convert -size 256x256 "xc:$$bg_color" "$$1" -resize 256x256 -composite -unsharp 0.5x0.5+0.5+0.008 "$$2"' >> $(SCRIPT_NAME); \
		echo 'else' >> $(SCRIPT_NAME); \
		echo '  convert "$$1" -resize 256x256 -unsharp 0.5x0.5+0.5+0.008 "$$2"' >> $(SCRIPT_NAME); \
		echo 'fi' >> $(SCRIPT_NAME); \
	else \
		echo "bg_color=\"none\"  # Прозрачный фон" >> $(SCRIPT_NAME); \
	fi
	
	@echo 'mkdir -p "$$temp_dir"' >> $(SCRIPT_NAME)
	@echo 'cd "$$temp_dir" || exit 1' >> $(SCRIPT_NAME)
	@echo 'wrestool -x -t 14 "$$input" -o "temp.ico" >/dev/null 2>&1' >> $(SCRIPT_NAME)
	@echo 'if [ -f "temp.ico" ]; then' >> $(SCRIPT_NAME)
	@echo '  icotool -x "temp.ico" >/dev/null 2>&1' >> $(SCRIPT_NAME)
	@echo '  largest_png=$$(find . -name "temp_*.png" -exec du -b {} + | sort -nr | head -n1 | cut -f2)' >> $(SCRIPT_NAME)
	@echo '  if [ -f "$$largest_png" ]; then' >> $(SCRIPT_NAME)
	@echo '    if [ "$$bg_color" != "none" ]; then' >> $(SCRIPT_NAME)
	@echo '      convert -size 256x256 "xc:$$bg_color" "$$largest_png" -resize 256x256 -composite -unsharp 0.5x0.5+0.5+0.008 "$$output"' >> $(SCRIPT_NAME)
	@echo '    else' >> $(SCRIPT_NAME)
	@echo '      convert "$$largest_png" -resize 256x256 -unsharp 0.5x0.5+0.5+0.008 "$$output"' >> $(SCRIPT_NAME)
	@echo '    fi' >> $(SCRIPT_NAME)
	@echo '  fi' >> $(SCRIPT_NAME)
	@echo 'fi' >> $(SCRIPT_NAME)
	@echo 'if [ ! -f "$$output" ]; then' >> $(SCRIPT_NAME)
	@echo '  if [ "$$bg_color" != "none" ]; then' >> $(SCRIPT_NAME)
	@echo '    convert -size 256x256 "xc:$$bg_color" "/usr/share/icons/Adwaita/256x256/mimetypes/application-x-executable.png" -resize 224x224 -gravity center -composite "$$output"' >> $(SCRIPT_NAME)
	@echo '  else' >> $(SCRIPT_NAME)
	@echo '    convert "/usr/share/icons/Adwaita/256x256/mimetypes/application-x-executable.png" -resize 256x256 "$$output"' >> $(SCRIPT_NAME)
	@echo '  fi' >> $(SCRIPT_NAME)
	@echo 'fi' >> $(SCRIPT_NAME)
	@echo 'rm -rf "$$temp_dir"' >> $(SCRIPT_NAME)
	@echo 'exit 0' >> $(SCRIPT_NAME)
	
	@echo "Установка скрипта в $(INSTALL_DIR)..."
	@su -c "cp $(SCRIPT_NAME) $(INSTALL_DIR)/$(SCRIPT_NAME) && chmod +x $(INSTALL_DIR)/$(SCRIPT_NAME)"
	@rm -f $(SCRIPT_NAME)

install-thumbnailer:
	@echo "Создание файла thumbnailer..."
	@echo "[Thumbnailer Entry]" > $(THUMBNAILER_NAME)
	@echo "Exec=$(INSTALL_DIR)/$(SCRIPT_NAME) %i %o" >> $(THUMBNAILER_NAME)
	@echo "MimeType=application/x-dosexec;application/x-ms-dos-executable;application/vnd.microsoft.portable-executable" >> $(THUMBNAILER_NAME)
	
	@echo "Установка thumbnailer в $(THUMBNAILER_DIR)..."
	@su -c "cp $(THUMBNAILER_NAME) $(THUMBNAILER_DIR)/$(THUMBNAILER_NAME)"
	@rm -f $(THUMBNAILER_NAME)

cleanup:
	@echo "Очистка кэша превью..."
	@-pkill nautilus 2>/dev/null || true
	@-rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
	@echo "Для завершения установки перезапустите Nautilus"
