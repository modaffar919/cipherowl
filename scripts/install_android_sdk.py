"""Install Android SDK components without Android Studio."""
import subprocess, os, sys

JAVA17 = r"C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot"
SDK    = os.path.expandvars(r"%LOCALAPPDATA%\Android\Sdk")
SDKMAN = os.path.join(SDK, r"cmdline-tools\latest\bin\sdkmanager.bat")
YES    = ("y\n" * 5).encode()

env = os.environ.copy()
env['JAVA_HOME']    = JAVA17
env['ANDROID_HOME'] = SDK
env['PATH']         = JAVA17 + r"\bin;" + env.get('PATH', '')

PACKAGES = [
    "platform-tools",
    "platforms;android-35",
    "build-tools;35.0.0",
]

def run(pkg):
    print(f"\n>>> Installing {pkg} ...", flush=True)
    r = subprocess.run(
        [SDKMAN, f'--sdk_root={SDK}', pkg],
        input=YES, env=env,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        timeout=600,
    )
    out = r.stdout.decode('utf-8', errors='replace')
    # Print last few lines
    lines = [l for l in out.splitlines() if l.strip()]
    print('\n'.join(lines[-5:]), flush=True)
    print(f">>> Exit: {r.returncode}", flush=True)
    return r.returncode

for pkg in PACKAGES:
    rc = run(pkg)
    if rc != 0:
        print(f"FAILED: {pkg}", file=sys.stderr)

# Point Flutter to the SDK
print("\n>>> Configuring Flutter SDK path...", flush=True)
subprocess.run([r"C:\src\flutter\bin\flutter.bat", "config", "--android-sdk", SDK],
               capture_output=True)

# Run doctor
print(">>> Flutter doctor...", flush=True)
r = subprocess.run([r"C:\src\flutter\bin\flutter.bat", "doctor"],
                   capture_output=True, text=True, timeout=60)
for line in r.stdout.splitlines():
    if any(x in line for x in ['Android', '√', 'X', '!']):
        print(line)

print("\nINSTALL_COMPLETE")
