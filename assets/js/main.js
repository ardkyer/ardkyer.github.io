$(document).ready(function () {
    $('#calendar').fullCalendar({
        events: [
            {% for post in site.posts %}
            {
            title: '{{ post.title }}',
            start: '{{ post.date | date: "%Y-%m-%d" }}',
            url: '{{ post.url | relative_url }}'
        },
        {% endfor %}
        ],
    eventClick: function (event) {
        if (event.url) {
            window.location.href = event.url;
            return false;
        }
    }
    });
});