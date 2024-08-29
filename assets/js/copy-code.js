document.addEventListener('DOMContentLoaded', (event) => {
    document.querySelectorAll('pre.highlight').forEach((block) => {
        const button = document.createElement('button');
        button.innerHTML = 'Copy';
        button.className = 'copy-button';
        block.appendChild(button);

        button.addEventListener('click', () => {
            const code = block.querySelector('code').innerText.trim();
            navigator.clipboard.writeText(code);
            button.innerHTML = 'Copied!';
            setTimeout(() => {
                button.innerHTML = 'Copy';
            }, 2000);
        });
    });
});