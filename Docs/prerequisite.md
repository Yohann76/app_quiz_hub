Install flutter on linux

```
cd ~ && mkdir -p development && cd development

sudo apt-get update && sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa

cd ~/development && curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz -o flutter.tar.xz

cd ~/development && tar xf flutter.tar.xz && rm flutter.tar.xz

ls -la ~/development/flutter/bin/flutter

grep -q "flutter/bin" ~/.bashrc || echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.bashrc

export PATH="$HOME/development/flutter/bin:$PATH" && flutter doctor

sudo apt-get install -y clang cmake ninja-build libgtk-3-dev

export PATH="$HOME/development/flutter/bin:$PATH" && flutter doctor -v

sudo apt-get install -y xvfb

cd /home/ubuntu/App/app_quiz_hub && export PATH="$HOME/development/flutter/bin:$PATH" && export DISPLAY=:99 && Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 & sleep 2 && flutter run -d chrome --web-renderer html 2>&1 | head -20

bash -c 'source ~/.bashrc && flutter --version'
```