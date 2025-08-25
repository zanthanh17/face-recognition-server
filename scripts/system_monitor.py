#!/usr/bin/env python3
"""
System monitoring script for the face recognition server.

Usage:
    python scripts/system_monitor.py --server-url http://localhost:8000 --check-interval 30
"""

import argparse
import json
import logging
import time
from datetime import datetime
from typing import Dict, Any

import requests
from requests.exceptions import RequestException

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class SystemMonitor:
    def __init__(self, server_url: str, auth_token: str = None):
        self.server_url = server_url.rstrip('/')
        self.auth_token = auth_token
        self.headers = {}
        if auth_token:
            self.headers['Authorization'] = f'Bearer {auth_token}'
    
    def check_health(self) -> Dict[str, Any]:
        """Check server health status."""
        try:
            response = requests.get(f"{self.server_url}/health", timeout=10)
            response.raise_for_status()
            return {
                "status": "healthy",
                "response_time": response.elapsed.total_seconds(),
                "data": response.json()
            }
        except RequestException as e:
            return {
                "status": "unhealthy",
                "error": str(e),
                "response_time": None,
                "data": None
            }
    
    def get_config(self) -> Dict[str, Any]:
        """Get server configuration."""
        try:
            response = requests.get(f"{self.server_url}/config", timeout=10)
            response.raise_for_status()
            return {
                "status": "success",
                "data": response.json()
            }
        except RequestException as e:
            return {
                "status": "error",
                "error": str(e),
                "data": None
            }
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get Prometheus metrics."""
        try:
            response = requests.get(f"{self.server_url}/metrics", timeout=10)
            response.raise_for_status()
            # Parse basic metrics from Prometheus format
            metrics_text = response.text
            lines = metrics_text.split('\n')
            
            metrics = {}
            for line in lines:
                if line.startswith('#') or not line.strip():
                    continue
                
                parts = line.split(' ')
                if len(parts) >= 2:
                    metric_name = parts[0]
                    try:
                        metric_value = float(parts[1])
                        metrics[metric_name] = metric_value
                    except ValueError:
                        continue
            
            return {
                "status": "success",
                "metrics": metrics,
                "raw_text": metrics_text
            }
        except RequestException as e:
            return {
                "status": "error",
                "error": str(e),
                "metrics": None
            }
    
    def get_users(self) -> Dict[str, Any]:
        """Get user list if auth is available."""
        if not self.auth_token:
            return {"status": "skipped", "reason": "No auth token provided"}
        
        try:
            response = requests.get(f"{self.server_url}/users", headers=self.headers, timeout=10)
            response.raise_for_status()
            return {
                "status": "success",
                "data": response.json()
            }
        except RequestException as e:
            return {
                "status": "error",
                "error": str(e),
                "data": None
            }
    
    def run_health_check(self) -> Dict[str, Any]:
        """Run comprehensive health check."""
        timestamp = datetime.now().isoformat()
        
        logger.info("Running health check...")
        
        # Check health endpoint
        health_result = self.check_health()
        logger.info(f"Health check: {health_result['status']}")
        
        # Get configuration
        config_result = self.get_config()
        logger.info(f"Config check: {config_result['status']}")
        
        # Get metrics
        metrics_result = self.get_metrics()
        logger.info(f"Metrics check: {metrics_result['status']}")
        
        # Get users (if auth available)
        users_result = self.get_users()
        logger.info(f"Users check: {users_result['status']}")
        
        return {
            "timestamp": timestamp,
            "server_url": self.server_url,
            "health": health_result,
            "config": config_result,
            "metrics": metrics_result,
            "users": users_result,
            "overall_status": "healthy" if health_result["status"] == "healthy" else "unhealthy"
        }
    
    def monitor_continuous(self, check_interval: int = 30):
        """Run continuous monitoring."""
        logger.info(f"Starting continuous monitoring (check every {check_interval}s)")
        
        while True:
            try:
                result = self.run_health_check()
                
                # Log summary
                status = result["overall_status"]
                response_time = result["health"].get("response_time")
                
                if status == "healthy":
                    logger.info(f"✓ System healthy (response: {response_time:.3f}s)")
                else:
                    logger.warning(f"✗ System unhealthy")
                
                # Optional: Save detailed results to file
                # with open(f"health_check_{datetime.now().strftime('%Y%m%d')}.jsonl", "a") as f:
                #     f.write(json.dumps(result) + "\n")
                
                time.sleep(check_interval)
                
            except KeyboardInterrupt:
                logger.info("Monitoring stopped by user")
                break
            except Exception as e:
                logger.error(f"Monitoring error: {e}")
                time.sleep(check_interval)


def main():
    parser = argparse.ArgumentParser(description="Monitor face recognition server health")
    parser.add_argument("--server-url", "-u", default="http://localhost:8000", 
                       help="Server URL (default: http://localhost:8000)")
    parser.add_argument("--auth-token", "-t", help="JWT authentication token")
    parser.add_argument("--check-interval", "-i", type=int, default=30,
                       help="Check interval in seconds for continuous monitoring (default: 30)")
    parser.add_argument("--continuous", "-c", action="store_true",
                       help="Run continuous monitoring")
    parser.add_argument("--output", "-o", help="Output file for detailed logs (JSON Lines format)")
    
    args = parser.parse_args()
    
    monitor = SystemMonitor(args.server_url, args.auth_token)
    
    if args.continuous:
        monitor.monitor_continuous(args.check_interval)
    else:
        # Single health check
        result = monitor.run_health_check()
        
        # Print results
        print(json.dumps(result, indent=2))
        
        # Save to file if specified
        if args.output:
            with open(args.output, "w") as f:
                json.dump(result, f, indent=2)
            logger.info(f"Results saved to {args.output}")


if __name__ == "__main__":
    main()





