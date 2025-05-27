# Makefile для установки превью .exe в Nautilus
.PHONY: install uninstall check-deps install-files cleanup

INSTALL_DIR = /usr/local/bin
THUMBNAILER_DIR = /usr/share/thumbnailers
SCRIPT_NAME = exe-thumbnailer
THUMBNAILER_NAME = exe.thumbnailer

install: check-deps install-files cleanup
	@echo "Установка завершена успешно!"

uninstall:
	@echo "Удаление EXE thumbnailer..."
	@if [ -f $(INSTALL_DIR)/$(SCRIPT_NAME) ] || [ -f $(THUMBNAILER_DIR)/$(THUMBNAILER_NAME) ]; then \
		echo "Требуются права root для удаления"; \
		sudo sh -c '\
			rm -f $(INSTALL_DIR)/$(SCRIPT_NAME); \
			rm -f $(THUMBNAILER_DIR)/$(THUMBNAILER_NAME); \
			echo "Файлы удалены."; \
		'; \
	else \
		echo "Файлы уже удалены."; \
	fi
	@echo "Не забудьте очистить кэш: rm -rf ~/.cache/thumbnails/*"

check-deps:
	@echo "Проверка зависимостей..."
	@if ! command -v wrestool >/dev/null 2>&1 || ! command -v convert >/dev/null 2>&1; then \
		echo "Требуются права root для установки зависимостей"; \
		sudo apt-get install -y icoutils imagemagick; \
	else \
		echo "Все зависимости уже установлены."; \
	fi

install-files:
	@echo "Создание временных файлов..."
	@echo "#!/bin/bash" > /tmp/$(SCRIPT_NAME)
	@echo "input=\"\$$1\"" >> /tmp/$(SCRIPT_NAME)
	@echo "output=\"\$$2\"" >> /tmp/$(SCRIPT_NAME)
	@echo "temp_dir=\"/tmp/exe-thumbnailer-\$$\"" >> /tmp/$(SCRIPT_NAME)
	
	@read -p "Хотите указать цвет фона вместо шахматного? [y/N] " choice; \
	if [ "$$choice" = "y" ] || [ "$$choice" = "Y" ]; then \
		read -p "Введите цвет в формате #xxxxxx: " bg_color; \
		echo "bg_color=\"$$bg_color\"  # Цвет подложки" >> /tmp/$(SCRIPT_NAME); \
	else \
		echo "bg_color=\"none\"  # Прозрачный фон" >> /tmp/$(SCRIPT_NAME); \
	fi
	
	@cat << 'EOF' >> /tmp/$(SCRIPT_NAME)
	mkdir -p "$$temp_dir"
	cd "$$temp_dir" || exit 1

	wrestool -x -t 14 "$$input" -o "temp.ico" >/dev/null 2>&1

	if [ -f "temp.ico" ]; then
		icotool -x "temp.ico" >/dev/null 2>&1
		largest_png=$$(find . -name "temp_*.png" -exec du -b {} + | sort -nr | head -n1 | cut -f2)

		if [ -f "$$largest_png" ]; then
			if [ "$$bg_color" != "none" ]; then
				convert -size 256x256 "xc:$$bg_color" "$$largest_png" -resize 256x256 -composite -unsharp 0.5x0.5+0.5+0.008 "$$output"
			else
				convert "$$largest_png" -resize 256x256 -unsharp 0.5x0.5+0.5+0.008 "$$output"
			fi
		fi
	fi

	if [ ! -f "$$output" ]; then
		if [ "$$bg_color" != "none" ]; then
			convert -size 256x256 "xc:$$bg_color" "/usr/share/icons/Adwaita/256x256/mimetypes/application-x-executable.png" -resize 224x224 -gravity center -composite "$$output"
		else
			convert "/usr/share/icons/Adwaita/256x256/mimetypes/application-x-executable.png" -resize 256x256 "$$output"
		fi
	fi

	rm -rf "$$temp_dir"
	exit 0
	EOF
	
	@echo "[Thumbnailer Entry]" > /tmp/$(THUMBNAILER_NAME)
	@echo "Exec=$(INSTALL_DIR)/$(SCRIPT_NAME) %i %o" >> /tmp/$(THUMBNAILER_NAME)
	@echo "MimeType=application/x-dosexec;application/x-ms-dos-executable;application/vnd.microsoft.portable-executable" >> /tmp/$(THUMBNAILER_NAME)
	
	@echo "Установка файлов (требуются права root)..."
	@sudo sh -c '\
		cp /tmp/$(SCRIPT_NAME) $(INSTALL_DIR)/$(SCRIPT_NAME); \
		chmod +x $(INSTALL_DIR)/$(SCRIPT_NAME); \
		cp /tmp/$(THUMBNAILER_NAME) $(THUMBNAILER_DIR)/$(THUMBNAILER_NAME); \
		rm -f /tmp/$(SCRIPT_NAME) /tmp/$(THUMBNAILER_NAME); \
	'
	@echo "Файлы установлены."

cleanup:
	@echo "Очистка кэша превью..."
	@-pkill nautilus 2>/dev/null || true
	@-rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
	@echo "Для завершения установки перезапустите Nautilus"
