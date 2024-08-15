---
layout: default
title: 논문 리뷰
---

<div class="paper-reviews-container">
  <h1 class="page-title">논문 리뷰</h1>

  <div class="reviews-grid">
    {% for review in site.paper_reviews %}
      <div class="review-card" data-url="{{ review.url | relative_url }}">
        <h2 class="review-title"><a href="{{ review.url | relative_url }}">{{ review.title }}</a></h2>
        <p class="review-date">작성일: {{ review.date | date: "%Y-%m-%d" }}</p>
        <p class="review-excerpt">{{ review.excerpt | strip_html | truncatewords: 30 }}</p>
      </div>
    {% endfor %}
  </div>
</div>

<script>
document.querySelectorAll('.review-card').forEach(function(card) {
  card.addEventListener('click', function(e) {
    if (!e.target.closest('a')) {
      window.location.href = this.getAttribute('data-url');
    }
  });
});
</script>