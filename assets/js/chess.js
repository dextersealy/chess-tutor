const csrf_token = $('meta[name="authenticity_token"]').attr('content');
$.ajaxPrefilter(function(options, originalOptions, jqXHR){
    if (options.type.toLowerCase() === 'post') {
        options.data = options.data || '';
        options.data += options.data ? '&' : '';
        options.data += 'authenticity_token=' + csrf_token;
    }
});

$(() => {
  const app = new App;
  app.start();
})
