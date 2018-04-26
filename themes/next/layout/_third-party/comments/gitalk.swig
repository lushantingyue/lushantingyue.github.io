{% if page.comments && theme.gitalk.enable %}

  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/gitalk@1.2.2/dist/gitalk.css">
  <script src="https://cdn.jsdelivr.net/npm/gitalk@1.2.2/dist/gitalk.min.js"></script>
  <script src="https://cdn.bootcss.com/blueimp-md5/2.10.0/js/md5.js"></script> <!-- 使用md5处理缩短文章标题的长编码 -->
  
  <script type="text/javascript">    
    var gitalk = new Gitalk({
        clientID: '{{ theme.gitalk.ClientID }}',
        clientSecret: '{{ theme.gitalk.ClientSecret }}',
        repo: '{{ theme.gitalk.repo }}',
        owner: '{{ theme.gitalk.githubID }}',
        admin: ['{{ theme.gitalk.adminUser }}'],
        id: md5(location.pathname),
        distractionFreeMode: '{{ theme.gitalk.distractionFreeMode }}'
      })
    gitalk.render('gitalk-container')           
  </script>

{% endif %}