# Flux Panel

This project is based on [https://github.com/bqlpfy/flux-panel](https://github.com/bqlpfy/flux-panel). Special thanks to the original author for their contribution.
It leverages [go-gost/gost](https://github.com/go-gost/gost) and [go-gost/x](https://github.com/go-gost/x) to implement a traffic forwarding panel.

---

## Features

- **Traffic Management**: Manage traffic forwarding quotas at the **tunnel account level**, suitable for user/tunnel quota control.
- **Protocol Support**: Supports both **TCP** and **UDP** protocols.
- **Forwarding Modes**: Supports two modes: **Port Forwarding** and **Tunnel Forwarding**.
- **Speed Limiting**: Supports **speed limit settings** for specific tunnels of specific users.
- **Billing Flexibility**: Supports configuration for **uni-directional or bi-directional traffic billing**, adapting to various billing models.
- **Flexible Strategies**: Provides flexible forwarding strategy configurations suitable for various network scenarios.

## Deployment

### Docker Compose Deployment

#### Quick Start

**Panel (Stable):**
```bash
curl -L https://raw.githubusercontent.com/missuo/flux-panel/refs/heads/main/panel_install.sh -o panel_install.sh && chmod +x panel_install.sh && ./panel_install.sh
```

**Node (Stable):**
```bash
curl -L https://raw.githubusercontent.com/missuo/flux-panel/refs/heads/main/install.sh -o install.sh && chmod +x install.sh && ./install.sh
```

#### Default Administrator Account

- **Username**: admin_user
- **Password**: admin_user

> ⚠️ Please change the default password immediately after the first login!

## iOS App

Download the iOS App via TestFlight: [https://testflight.apple.com/join/vxkZ9xzn](https://testflight.apple.com/join/vxkZ9xzn)

## Disclaimer

This project is for personal learning and research purposes only and is a secondary development based on open-source projects.

Any risks associated with using this project are solely borne by the user, including but not limited to:

- Service abnormalities or unavailability caused by improper configuration or misuse;
- Network attacks, bans, or abuse resulting from the use of this project;
- Data leakage, resource consumption, or loss caused by server intrusion, penetration, or abuse due to the use of this project;
- Any legal liabilities arising from violation of local laws and regulations.

This project is an open-source traffic forwarding tool intended only for legal and compliant purposes.
Users must ensure that their usage complies with the laws and regulations of their country or region.

**The author assumes no responsibility for any legal liability, economic loss, or other consequences caused by the use of this project.**
**It is prohibited to use this project for any illegal or unauthorized activities, including but not limited to network attacks, data theft, and illegal access.**

If you do not agree to the above terms, please stop using this project immediately.

The author is not responsible for any direct or indirect losses caused by the use of this project, nor does the author provide any form of guarantee, commitment, or technical support.

Please ensure that you use this project under legal, compliant, and safe conditions.

