const chokidar = require('chokidar');
const { execSync } = require('child_process');

console.log('👀 src/ フォルダの監視を開始しました。');
console.log('💡 保存すると5秒後に自動でGitHubへ同期（プッシュ）します。');

let pushTimeout = null;

chokidar.watch('./src', { ignoreInitial: true }).on('all', (event, filePath) => {
    if (filePath.includes('base.lua') || filePath.includes('.git')) return;

    console.log(`📝 変更を検出: ${filePath}`);

    if (pushTimeout) clearTimeout(pushTimeout);

    pushTimeout = setTimeout(() => {
        // 先に base.lua を最新状態に同期させてからプッシュする
        try {
            // ① base.lua の再生成
            execSync('node -e "require(\'./watch.js\').generateGameBaseFiles()"', { stdio: 'ignore' });
        } catch(e) {
            // watch.jsが別の記述になっている場合は、手動でgenerateGameBaseFilesを実行する仕組みに合わせる
        }

        console.log('\n📤 GitHubへ送信中...');
        try {
            execSync('git add .', { stdio: 'inherit' });
            execSync('git commit -m "Sync source files"', { stdio: 'inherit' });
            execSync('git push origin main', { stdio: 'inherit' });
            console.log('✅ 送信完了！最新のコードが即座に反映されました。\n');
        } catch (error) {
            console.error('❌ 送信失敗\n');
        }
    }, 5000);
});