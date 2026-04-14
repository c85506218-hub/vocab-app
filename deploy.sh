#!/bin/bash
# GitHub Pages 自動部署腳本

echo "=============================="
echo "  vocab-app 部署到 GitHub Pages"
echo "=============================="
echo ""

# 讀取 Token（不顯示在螢幕上）
read -s -p "請貼上你的 GitHub Token (ghp_...): " TOKEN
echo ""

if [ -z "$TOKEN" ]; then
  echo "❌ Token 不能為空"
  exit 1
fi

# 取得 GitHub 用戶名稱
echo "⏳ 驗證 Token..."
USERNAME=$(curl -s -H "Authorization: token $TOKEN" https://api.github.com/user | python3 -c "import sys,json; print(json.load(sys.stdin)['login'])" 2>/dev/null)

if [ -z "$USERNAME" ]; then
  echo "❌ Token 無效或已過期，請重新產生"
  exit 1
fi

echo "✅ 已登入為：$USERNAME"
echo ""

REPO_NAME="vocab-app"
FILE_PATH="/Users/ccleo/Downloads/vocab-app/index.html"

# 建立 repo（如果已存在會忽略錯誤）
echo "⏳ 建立 repository: $REPO_NAME ..."
CREATE_RESULT=$(curl -s -X POST \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$REPO_NAME\",\"private\":false,\"description\":\"英文單字複習 App\"}" \
  https://api.github.com/user/repos)

# 檢查是否已存在
if echo "$CREATE_RESULT" | grep -q '"already_exists"'; then
  echo "ℹ️  Repository 已存在，繼續更新檔案..."
elif echo "$CREATE_RESULT" | grep -q '"full_name"'; then
  echo "✅ Repository 建立成功"
else
  # 可能已存在，嘗試繼續
  echo "ℹ️  繼續上傳檔案..."
fi

# 將 index.html 轉為 base64
echo "⏳ 上傳 index.html..."
CONTENT=$(base64 < "$FILE_PATH")

# 檢查是否已有該檔案（取得 SHA）
SHA=$(curl -s \
  -H "Authorization: token $TOKEN" \
  "https://api.github.com/repos/$USERNAME/$REPO_NAME/contents/index.html" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sha',''))" 2>/dev/null)

# 上傳或更新檔案
if [ -n "$SHA" ]; then
  UPLOAD_DATA="{\"message\":\"update vocab app\",\"content\":\"$CONTENT\",\"sha\":\"$SHA\"}"
else
  UPLOAD_DATA="{\"message\":\"add vocab app\",\"content\":\"$CONTENT\"}"
fi

UPLOAD_RESULT=$(curl -s -X PUT \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$UPLOAD_DATA" \
  "https://api.github.com/repos/$USERNAME/$REPO_NAME/contents/index.html")

if echo "$UPLOAD_RESULT" | grep -q '"sha"'; then
  echo "✅ 檔案上傳成功"
else
  echo "❌ 上傳失敗："
  echo "$UPLOAD_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','未知錯誤'))" 2>/dev/null
  exit 1
fi

# 開啟 GitHub Pages
echo "⏳ 啟用 GitHub Pages..."
curl -s -X POST \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d '{"source":{"branch":"main","path":"/"}}' \
  "https://api.github.com/repos/$USERNAME/$REPO_NAME/pages" > /dev/null 2>&1

echo ""
echo "=============================="
echo "🎉 完成！"
echo ""
echo "你的 App 網址（約 1-2 分鐘後生效）："
echo "👉 https://$USERNAME.github.io/$REPO_NAME"
echo ""
echo "手機直接開瀏覽器輸入這個網址即可使用！"
echo "=============================="
