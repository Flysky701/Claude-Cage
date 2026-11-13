"""Runs inside the isolated upstream namespace, which has no physical interface."""
import os
import socketserver
import subprocess
import sys
import threading

class LocalCage(socketserver.BaseRequestHandler):
    def handle(self):
        p=subprocess.Popen([sys.argv[1],sys.argv[2],"stream"],stdin=subprocess.PIPE,
                           stdout=subprocess.PIPE,bufsize=0)
        def send():
            try:
                while data:=self.request.recv(65536):
                    view=memoryview(data)
                    while view: view=view[os.write(p.stdin.fileno(),view):]
            except OSError: pass
            finally: p.stdin.close()
        threading.Thread(target=send,daemon=True).start()
        try:
            while data:=os.read(p.stdout.fileno(),65536): self.request.sendall(data)
        except OSError: pass
        finally:
            p.terminate()
            p.wait()

class LocalServer(socketserver.ThreadingTCPServer):
    allow_reuse_address=True
    daemon_threads=True

with LocalServer(("198.51.100.2",1080),LocalCage) as server: server.serve_forever()
