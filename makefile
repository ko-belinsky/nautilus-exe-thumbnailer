.PHONY: install uninstall

install:
	@echo "Проверка зависимостей..."
	@if ! which wrestool >/dev/null || ! which convert >/dev/null; then \
		echo "Установка icoutils и imagemagick..."; \
		su -c "apt-get install -y icoutils imagemagick"; \
	fi
	
	@echo "Установка файлов..."
	@su -c "cp exe-thumbnailer /usr/local/bin/ && \
		cp exe.thumbnailer /usr/share/thumbnailers/ && \
		chmod +x /usr/local/bin/exe-thumbnailer"
	
	@echo "Перезапуск Nautilus..."
	@pkill nautilus && rm -rf $$HOME/.cache/thumbnails/*
	@echo "Установка завершена!"

uninstall:
	@echo "Удаление файлов..."
	@su -c "rm -f /usr/local/bin/exe-thumbnailer /usr/share/thumbnailers/exe.thumbnailer"
	@echo "Очистка кэша..."
	@pkill nautilus && rm -rf $$HOME/.cache/thumbnails/*
	@echo "Удаление завершено"
