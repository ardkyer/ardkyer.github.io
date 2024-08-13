---
layout: default
title: 캘린더
---

<div id="calendar"></div>

<script>
document.addEventListener('DOMContentLoaded', function() {
  var calendarEl = document.getElementById('calendar');
  window.calendar = new FullCalendar.Calendar(calendarEl, {
    initialView: 'dayGridMonth',
    headerToolbar: {
      left: '',
      center: 'title',
      right: 'prev,next today' 
    },
    events: [
      {% for post in site.posts %}
      {
        title: '{{ post.title | escape }}',
        start: '{{ post.date | date: "%Y-%m-%d" }}',
        url: '{{ post.url | relative_url }}',
        extendedProps: {
          post_id: '{{ post.id }}'
        }
      },
      {% endfor %}
    ],
    eventClick: function(info) {
      info.jsEvent.preventDefault();
      if (info.event.url) {
        window.location.href = info.event.url;
      }
    },
    eventContent: function(arg) {
      return {
        html: '<div class="fc-event-title" style="white-space: normal; overflow: hidden; text-overflow: ellipsis;">' + arg.event.title + '</div>'
      };
    },
    dayCellContent: function(arg) {
      return {
        html: '<div class="fc-daygrid-day-number">' + arg.dayNumberText + '</div>'
      };
    },
    eventDidMount: function(info) {
      info.el.setAttribute('title', info.event.title);
    }
  });
  window.calendar.render();
});
</script>