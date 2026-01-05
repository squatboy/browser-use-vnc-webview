# Browser-Use Web View

[![BrowserUse](https://img.shields.io/badge/BrowserUse-0.11.2-black?style=flat&logo=github)](https://github.com/browser-use/browser-use)
![Python](https://img.shields.io/badge/Python-3.11-blue?style=flat&logo=python)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115.6-success?style=flat&logo=fastapi)

Browser-Use Web View is a container-based environment designed to provide real-time web access to the headful browser of a browser-use agent via VNC/noVNC. <br> The system features a structure where vnc and agent containers communicate through a shared X11 UNIX socket, ensuring session isolation and security while safely visualizing automated browser operations on a virtual monitor.


## System Architecture 

<img width="996" height="933" alt="473523324-d86b43ec-4204-4a94-ae86-01c63c39dfe1" src="https://github.com/user-attachments/assets/4431006a-1656-49ce-b97c-07b719b23743" />

### Multi-Session Flow
<img width="1138" height="570" alt="image" src="https://github.com/user-attachments/assets/8379e126-1940-4096-8857-3cdb141f4ad6" />


When a user requests the execution of a browser-use task, the orchestrator triggers the creation of a new session. For each session, a VNC/agent container pair is launched independently, and a real-time virtual monitor screen is provided via noVNC. Each session runs completely isolated using Docker namespaces and dedicated X11 socket volumes, ensuring that display data is securely separated between sessions.

## Demo

![vncsingle](https://github.com/user-attachments/assets/6468d96a-6f57-411f-9012-c39017110ff6)


#### Multi Session

![multisession](https://github.com/user-attachments/assets/f7d62f1d-575e-475a-8462-a9167ee1a9d6)


## Containers

### vnc

- **Xvfb**: Virtual display server (e.g., :99)
- **x11vnc**: VNC server
- **websockify**: Converts VNC to WebSocket for noVNC access

### agent

- Executes browser-use Python scripts (e.g., `agent.py`)
- Shares the X11 socket volume with the `vnc` container to render output to the virtual display


## Getting Started

### Requirements

- Docker & Docker Compose
- git
- Python 3.8 or higher

### 1. Clone the Repository

```bash
git clone https://github.com/squatboy/browser-use-vnc.git
cd browser-use-vnc/
```

### 2. Prepare `.env` Files and Agent Script
- `agent/.env`: Write the LLM API KEY to be used by Browser-Use.
- Browser-Use agent script file: `agent/agent.py`
- `orchestrator/.env`: Specify `PUBLIC_HOST=<Server public IP or domain>` (must be set in this file; used by the orchestrator to generate the noVNC access URL).

> These files are automatically loaded by Docker Compose to configure and run the agent and orchestrator containers.

### 3. Pre-build Docker Images

Before starting the orchestrator, pre-build the Docker images to avoid long delays during session creation:

```bash
./prebuild.sh
```

This script will build both the VNC and agent images. Once completed, session creation will be much faster since the images are already available.

> **Note**: Make sure Docker Desktop is running before executing this script.

### 4. Run the FastAPI Orchestrator

To run the orchestrator service that manages session creation, follow these steps:

1. **Create and activate a Python virtual environment inside the `orchestrator/` folder:**
    ```bash
    cd orchestrator
    python3 -m venv .venv
    source .venv/bin/activate
    ```
2. **Upgrade pip and install dependencies from `requirements.txt`:**
    ```bash
    pip install -U pip
    pip install -r requirements.txt
    ```
3. **Run the FastAPI server using uvicorn:**
    ```bash
    uvicorn app_orchestrator:app --host 0.0.0.0 --port 8000 --reload
    ```

### 5. Create a New Session

Send a POST request to create a new VNC/agent session:

```bash
curl -X POST http://<Server-IP>:8000/sessions
```

The response includes the session ID and the dynamically assigned noVNC url

Example Response:
```json
{
  "session_id": "1a2b3c4d",
  "novnc_url": "http://<Server-IP>:6081/vnc.html?autoconnect=true&resize=scale"
}
```

### 5. Connect to the Session

Open the provided URL in your web browser to connect to the virtual monitor via noVNC.

## Manual Multi-Session Test Example

Without using orchestration, you can manually create multiple independent sessions by specifying different `SESSION_ID` and `NOVNC_PORT` environment variables and running separate Docker Compose projects.

```bash
# First session
cd vnc/
SESSION_ID=session1 NOVNC_PORT=6081 docker compose -p vnc1 up -d --build

# Second session
SESSION_ID=session2 NOVNC_PORT=6082 docker compose -p vnc2 up -d --build
```

<img width="928" height="106" alt="image" src="https://github.com/user-attachments/assets/53324c5a-73c9-46ac-80e9-52d1425d3acd" />


Then connect to each session:

- http://:6081/vnc.html
- http://:6082/vnc.html

<img width="743" height="97" alt="image" src="https://github.com/user-attachments/assets/a28b3676-ba04-4cb4-a7b3-3f38b23fc703" />

<img width="743" height="97" alt="image" src="https://github.com/user-attachments/assets/cf943c7b-6e0b-4b32-be41-d61ed2986cf4" />


Each session uses its own dedicated X11 socket volume, ensuring isolation with no data leakage between sessions.


## Security Group & Network Configuration

When deploying on a public server, open only the noVNC ports required for your sessions (e.g., 6080, 6081, 6082, ...). Restrict access as necessary for security.


## BrowserSession Python Configuration Example

When running browsers inside the agent container, use the following settings to avoid common Docker-related issues:

```python
browser_session = BrowserSession(
    headless=False,
    args=[
        "--no-sandbox",            # Required when running as root in Docker
        "--disable-dev-shm-usage"  # Prevent crashes with limited /dev/shm in containers
    ],
)
```



## Customization & Advanced Usage

- The system separates the `vnc` container (virtual display and VNC services) and the `agent` container (browser automation scripts).
- Extend or modify the agent scripts (`agent.py`) to fit your automation workflows.
- The agent container connects to the shared X11 socket volume to render browser output on the virtual display managed by the vnc container.


## Use Case: Embedding the VNC Desktop in a Website

Embed the noVNC web client in an iframe to integrate the remote desktop directly into your web application:

```html
<iframe
    src="http://<Server-IP>:6080/vnc.html?autoconnect=true"
    width="1280" height="720">
</iframe>
```



## Troubleshooting & Tips

- **Chrome fails to launch**: Restart the containers with `docker compose restart`.
- **VNC connection fails**: Check whether inbound traffic on the noVNC ports is allowed by your firewall or security group.


## Additional Notes

- Each session is isolated via Docker namespaces and dedicated X11 socket volumes.
- Communication between the `agent` and `vnc` containers occurs only through the X11 UNIX socket, not over the network.
- You can freely add or modify agent-side scripts and dependencies to fit your use case.
