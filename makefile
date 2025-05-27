# Makefile for EXE thumbnailer installation
.PHONY: install uninstall check-deps install-script install-thumbnailer cleanup

INSTALL_DIR = /usr/local/bin
THUMBNAILER_DIR = /usr/share/thumbnailers
SCRIPT_NAME = exe-thumbnailer
THUMBNAILER_NAME = exe.thumbnailer

install: check-deps install-script install-thumbnailer cleanup
	@echo "Installation completed successfully!"

uninstall:
	@echo "Removing EXE thumbnailer..."
	@rm -f $(INSTALL_DIR)/$(SCRIPT_NAME)
	@rm -f $(THUMBNAILER_DIR)/$(THUMBNAILER_NAME)
	@echo "Uninstallation complete. Don't forget to clear cache: rm -rf ~/.cache/thumbnails/*"

check-deps:
	@echo "Checking dependencies..."
	@if ! command -v wrestool >/dev/null 2>&1 || ! command -v convert >/dev/null 2>&1; then \
		echo "Installing icoutils and imagemagick..."; \
		su -c 'apt-get install -y icoutils imagemagick'; \
	else \
		echo "All dependencies are already installed."; \
	fi

install-script:
	@echo "Creating $(SCRIPT_NAME) script..."
	@echo "#!/bin/bash" > $(SCRIPT_NAME)
	@echo "input=\"\$$1\"" >> $(SCRIPT_NAME)
	@echo "output=\"\$$2\"" >> $(SCRIPT_NAME)
	@echo "temp_dir=\"/tmp/exe-thumbnailer-\$$\"" >> $(SCRIPT_NAME)
	
	@read -p "Do you want to specify background color for checkerboard pattern? [y/N] " choice; \
	if [ "$$choice" = "y" ] || [ "$$choice" = "Y" ]; then \
		read -p "Enter color in #xxxxxx format: " bg_color; \
		echo "bg_color=\"$$bg_color\"  # Background color" >> $(SCRIPT_NAME); \
		echo 'convert_cmd() {' >> $(SCRIPT_NAME); \
		echo '  convert -size 256x256 "xc:$$bg_color" "$$1" -resize 256x256 -composite -unsharp 0.5x0.5+0.5+0.008 "$$2"' >> $(SCRIPT_NAME); \
		echo '}' >> $(SCRIPT_NAME); \
	else \
		echo "bg_color=\"none\"  # Transparent background" >> $(SCRIPT_NAME); \
		echo 'convert_cmd() {' >> $(SCRIPT_NAME); \
		echo '  convert "$$1" -resize 256x256 -unsharp 0.5x0.5+0.5+0.008 "$$2"' >> $(SCRIPT_NAME); \
		echo '}' >> $(SCRIPT_NAME); \
	fi
	
	@echo 'mkdir -p "$$temp_dir"' >> $(SCRIPT_NAME)
	@echo 'cd "$$temp_dir" || exit 1' >> $(SCRIPT_NAME)
	@echo 'wrestool -x -t 14 "$$input" -o "temp.ico" >/dev/null 2>&1' >> $(SCRIPT_NAME)
	@echo 'if [ -f "temp.ico" ]; then' >> $(SCRIPT_NAME)
	@echo '  icotool -x "temp.ico" >/dev/null 2>&1' >> $(SCRIPT_NAME)
	@echo '  largest_png=$$(find . -name "temp_*.png" -exec du -b {} + | sort -nr | head -n1 | cut -f2)' >> $(SCRIPT_NAME)
	@echo '  if [ -f "$$largest_png" ]; then' >> $(SCRIPT_NAME)
	@echo '    convert_cmd "$$largest_png" "$$output"' >> $(SCRIPT_NAME)
	@echo '  fi' >> $(SCRIPT_NAME)
	@echo 'fi' >> $(SCRIPT_NAME)
	@echo 'if [ ! -f "$$output" ]; then' >> $(SCRIPT_NAME)
	@echo '  if [ "$$bg_color" = "none" ]; then' >> $(SCRIPT_NAME)
	@echo '    convert "/usr/share/icons/Adwaita/256x256/mimetypes/application-x-executable.png" -resize 256x256 "$$output"' >> $(SCRIPT_NAME)
	@echo '  else' >> $(SCRIPT_NAME)
	@echo '    convert -size 256x256 "xc:$$bg_color" "/usr/share/icons/Adwaita/256x256/mimetypes/application-x-executable.png" -resize 224x224 -gravity center -composite "$$output"' >> $(SCRIPT_NAME)
	@echo '  fi' >> $(SCRIPT_NAME)
	@echo 'fi' >> $(SCRIPT_NAME)
	@echo 'rm -rf "$$temp_dir"' >> $(SCRIPT_NAME)
	@echo 'exit 0' >> $(SCRIPT_NAME)
	
	@echo "Installing script to $(INSTALL_DIR)..."
	@su -c "cp $(SCRIPT_NAME) $(INSTALL_DIR)/$(SCRIPT_NAME) && chmod +x $(INSTALL_DIR)/$(SCRIPT_NAME)"
	@rm -f $(SCRIPT_NAME)

install-thumbnailer:
	@echo "Creating thumbnailer file..."
	@echo "[Thumbnailer Entry]" > $(THUMBNAILER_NAME)
	@echo "Exec=$(INSTALL_DIR)/$(SCRIPT_NAME) %i %o" >> $(THUMBNAILER_NAME)
	@echo "MimeType=application/x-dosexec;application/x-ms-dos-executable;application/vnd.microsoft.portable-executable" >> $(THUMBNAILER_NAME)
	
	@echo "Installing thumbnailer to $(THUMBNAILER_DIR)..."
	@su -c "cp $(THUMBNAILER_NAME) $(THUMBNAILER_DIR)/$(THUMBNAILER_NAME)"
	@rm -f $(THUMBNAILER_NAME)

cleanup:
	@echo "Cleaning thumbnail cache..."
	@-pkill nautilus
	@-rm -rf ~/.cache/thumbnails/*
	@echo "Please restart Nautilus to complete installation"
