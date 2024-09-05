---
layout: default
title: 개발일지
permalink: /dev_logs/
---
<style>
.dev-logs-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
}
.page-title {
    font-size: 2.5rem;
    color: #333;
    margin-bottom: 2rem;
    text-align: center;
}
.logs-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 2rem;
}
.log-card {
    background-color: #fff;
    border-radius: 8px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    padding: 1.5rem;
    transition: transform 0.3s ease, box-shadow 0.3s ease;
    cursor: pointer;
}
.log-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
}
.log-title {
    font-size: 1.4rem;
    margin-bottom: 0.5rem;
}
.log-title a {
    color: #2c3e50;
    text-decoration: none;
}
.log-date {
    font-size: 0.9rem;
    color: #7f8c8d;
    margin-bottom: 1rem;
}
.log-excerpt {
    font-size: 1rem;
    color: #34495e;
    margin-bottom: 1rem;
}
</style>
<div class="dev-logs-container">
  <h1 class="page-title">개발일지</h1>
  <div class="logs-grid">
    {% for log in site.dev_logs %}
      <div class="log-card" data-url="{{ log.url | relative_url }}">
        <h2 class="log-title"><a href="{{ log.url | relative_url }}">{{ log.title }}</a></h2>
        <p class="log-date">작성일: {{ log.date | date: "%Y-%m-%d" }}</p>
        <p class="log-excerpt">{{ log.excerpt | strip_html | truncatewords: 30 }}</p>
      </div>
    {% endfor %}
  </div>
</div>
<script>
document.querySelectorAll('.log-card').forEach(function(card) {
  card.addEventListener('click', function(e) {
    if (!e.target.closest('a')) {
      window.location.href = this.getAttribute('data-url');
    }
  });
});
</script>