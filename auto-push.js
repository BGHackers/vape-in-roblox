const chokidar = require('chokidar');
const { execSync } = require('child_process');

// 🌟 同期までの待機時間を設定（ミリ秒単位: 1000ms = 1秒）
const SYNC_DELAY = 1000; 

console.log('👀 プロジェクト全体の監視を開始しました。');
console.log(`💡 保存すると${SYNC_DELAY / 1000}秒後に自動でGitHubへ同期（プッシュ）します。 (Ctrl+C で停止)`);

let pushTimeout = null;

// ルートディレクトリ「.」を監視対象にします
chokidar.watch('.', {
    // 監視から除外するフォルダやファイルをここに指定します
    ignored: [
        '**/node_modules/**',
        '**/.git/**',
        '**/base.lua',
        '**/bundle.lua',
        '**/package-lock.json',
        '**/auto-push.js', // 自身への書き込みによる無限ループ防止
        '**/watch.js'
    ],
    ignoreInitial: true
}).on('all', (event, filePath) => {
    // 予期せぬシステムファイルなどの変更を無視するセーフティ
    if (filePath.includes('.git') || filePath.includes('base.lua')) return;

    console.log(`📝 変更を検出: ${filePath}`);

    if (pushTimeout) clearTimeout(pushTimeout);

    pushTimeout = setTimeout(() => {
        // 先に base.lua を最新状態に同期させてからプッシュする
        try {
            execSync('node -e "require(\'./watch.js\').generateGameBaseFiles()"', { stdio: 'ignore' });
        } catch(e) {
            // watch.jsにエラーがある、または存在しない場合はスキップします
        }

        try {
            // すべての変更を仮追加
            execSync('git add .', { stdio: 'ignore' });

            // 変更差分があるかどうかを確認する処理
            const status = execSync('git status --porcelain').toString().trim();
            if (status === '') {
                console.log('\nℹ️ 変更がないため、GitHubへの送信をスキップします。\n');
                return; // 差分がなければ、ここで安全に送信処理を中止します
            }

            console.log('\n💾 差分をローカルにコミット中...');
            execSync('git commit -m "Sync source files and configs"', { stdio: 'inherit' });

            // 🌟 改善：プッシュ前にリモートの変更を安全に引き込む
            console.log('🔄 リモート(GitHub)の変更を取り込んでいます (git pull --rebase)...');
            execSync('git pull --rebase origin main', { stdio: 'inherit' });

            console.log('📤 GitHubへ送信中 (git push)...');
            execSync('git push origin main', { stdio: 'inherit' });
            console.log('✅ 送信完了！最新のコードが即座に反映されました。\n');
        } catch (error) {
            console.error('\n❌ 送信失敗（競合またはロックエラーが発生しました）');
            console.error('💡 【対策1】ターミナルで手動で「git pull --rebase origin main」を実行し、競合（コンフリクト）を解決してください。');
            console.error('💡 【対策2】VS Code等を使用している場合、設定から「Git: Autofetch」を「off」にすることをお勧めします（ロック競合を防ぐため）。\n');
        }
    }, SYNC_DELAY);
});