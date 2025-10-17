# Configuration Templates

This directory contains configuration templates used by the restore script.

## Files

### common_site_config.json

This is the default Frappe site configuration template that includes:

- **Redis Configuration**: Proper connection URLs for cache, queue, and socketio
- **Development Settings**: Live reload, file watcher, and other dev features
- **Worker Configuration**: Background workers and Gunicorn settings

**Important:** This file is automatically copied to the Docker container during the restore process to ensure proper Redis connectivity.

## Usage

The `restore.bat` script automatically uses this template. If you need to manually apply the configuration:

```cmd
docker cp config\common_site_config.json frappe-builder-frappe-1:/home/frappe/frappe-bench/sites/common_site_config.json
```

## Customization

You can modify the settings in `common_site_config.json` to adjust:

- Number of background workers
- Gunicorn worker count
- Port numbers
- Redis connection settings (if using different Redis setup)

After modifying, run the restore script again or manually copy the file to the container.
