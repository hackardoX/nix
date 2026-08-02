# Homepage Module

Dashboard for your homelab services using [Homepage](https://gethomepage.dev/).

## Usage

Enable Homepage in your configuration:

```nix
services.homepage = {
  enable = true;
  port = 3000;

  settings = {
    title = "My Homelab";
    theme = "dark";
    color = "slate";
  };

  widgets = [
    {
      resources = {
        cpu = true;
        memory = true;
        network = "eth0";
      };
    }
  ];
};
```

## Configuration Options

### services.homepage

- `enable`: Enable Homepage (default: false)
- `port`: Port to expose Homepage (default: 3000)
- `appDir`: Persistent data directory (default: /var/lib/containers/homepage)
- `settings`: Homepage settings (title, theme, color, etc.)
- `bookmarks`: List of bookmark configurations
- `widgets`: List of widget configurations
- `docker`: Docker integration configuration

## Network Architecture

Homepage runs on an isolated `homepage.network` bridge network. Services are accessed via host ports (e.g., `http://localhost:8080`), allowing Homepage to reach services without joining their networks.

## Docker Integration

Homepage automatically discovers services via Docker labels and displays container stats (CPU, memory, network) when configured. The Podman socket is mounted read-only for this integration.

## References

- [Homepage Documentation](https://gethomepage.dev/)
- [Homepage Widgets](https://gethomepage.dev/widgets/)
- [Dashboard Icons](https://github.com/walkxcode/dashboard-icons)
