(function () {
    function displaySearchResults(results, store) {
        var searchResults = document.getElementById('results-container');

        if (results.length) {
            var appendString = '';

            for (var i = 0; i < results.length; i++) {
                var item = store[results[i].ref];
                appendString += '<li><a href="' + item.url + '"><h3>' + item.title + '</h3></a>';
                appendString += '<p>' + item.content.substring(0, 150) + '...</p></li>';
            }

            searchResults.innerHTML = appendString;
        } else {
            searchResults.innerHTML = '<li>검색 결과가 없습니다.</li>';
        }
    }

    function getQueryVariable(variable) {
        var query = window.location.search.substring(1);
        var vars = query.split('&');

        for (var i = 0; i < vars.length; i++) {
            var pair = vars[i].split('=');

            if (pair[0] === variable) {
                return decodeURIComponent(pair[1].replace(/\+/g, '%20'));
            }
        }
    }

    var searchTerm = getQueryVariable('query');

    if (searchTerm) {
        document.getElementById('search-input').setAttribute("value", searchTerm);

        var idx = lunr(function () {
            this.field('id');
            this.field('title', { boost: 10 });
            this.field('category');
            this.field('content');
        });

        for (var key in window.store) {
            idx.add({
                'id': key,
                'title': window.store[key].title,
                'category': window.store[key].category,
                'content': window.store[key].content
            });
        }

        var results = idx.search(searchTerm);
        displaySearchResults(results, window.store);
    }
})();