---
layout: default
title: 논문 리뷰
---

# 논문 리뷰

{% for review in site.paper_reviews %}
  <h2><a href="{{ review.url | relative_url }}">{{ review.title }}</a></h2>
  <p>{{ review.date | date: "%Y-%m-%d" }}</p>
  {{ review.excerpt }}
{% endfor %}