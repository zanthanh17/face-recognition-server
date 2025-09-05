import os
import sys
from pathlib import Path

# Add project root to Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


def main() -> None:
    try:
        import uvicorn  # type: ignore
        from server.main import app  # Direct import instead of string
    except Exception as e:
        print(f"Please install server dependencies: pip install -r server/requirements-render.txt\nError: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Render requires host=0.0.0.0 and uses PORT environment variable
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    
    print(f"Starting server on {host}:{port}")
    uvicorn.run(app, host=host, port=port, reload=False, access_log=True)


if __name__ == "__main__":
    main()


