const chokidar = require('chokidar');
const { execSync } = require('child_process');

console.log('👀 src/ を監視中... (Ctrl+C で停止)');

chokidar.watch('./src', { ignoreInitial: true }).on('all', (event, filePath) => {
    console.log(`\n🔄 変更検出: ${filePath}`);
    try {
        execSync(
            'npx luabundler bundle ./src/Main.lua -p ./src/?.lua -p ./src/?/init.lua -o ./dist/bundle.lua',
            { stdio: 'inherit' }
        );
        console.log('✅ dist/bundle.lua を更新しました!');
    } catch (e) {
        console.error('❌ ビルド失敗');
    }
});