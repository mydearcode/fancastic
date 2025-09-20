// YouTube video işlemleri için JavaScript
document.addEventListener('turbo:load', function() {
  setupYoutubeEmbeds();
});

document.addEventListener('turbo:frame-load', function() {
  setupYoutubeEmbeds();
});

// Dinamik içerik için event delegation kullanımı
document.addEventListener('click', function(e) {
  // Tıklanan element veya üst elementlerinden biri youtube-embed sınıfına sahipse
  const youtubeEmbed = e.target.closest('.youtube-embed');
  if (youtubeEmbed) {
    e.stopPropagation();
    e.preventDefault();
    return false;
  }
}, true); // Capture phase'de çalıştır (event bubbling'den önce)

function setupYoutubeEmbeds() {
  // Tüm post linklerini bul
  const postLinks = document.querySelectorAll('.bg-black.border-b');
  
  postLinks.forEach(postLink => {
    // Post içindeki YouTube embedlerini bul
    const youtubeEmbeds = postLink.querySelectorAll('.youtube-embed');
    
    if (youtubeEmbeds.length > 0) {
      // Post link davranışını özelleştir
      postLink.addEventListener('click', function(e) {
        // Tıklanan element veya üst elementlerinden biri youtube-embed sınıfına sahipse
        const clickedYoutubeEmbed = e.target.closest('.youtube-embed');
        if (clickedYoutubeEmbed) {
          e.stopPropagation();
          e.preventDefault();
          return false;
        }
      });
      
      // Her bir YouTube embed için
      youtubeEmbeds.forEach(embed => {
        // Tüm içeriği kapsayacak şekilde tıklama olayını engelle
        // Position ve z-index ayarlarını kaldırdık, böylece dropdown menüler ve diğer içerikler doğru şekilde görüntülenecek
        
        // İframe'i bul
        const iframe = embed.querySelector('iframe');
        if (iframe) {
          iframe.style.pointerEvents = 'auto';
        }
        
        // Tüm linkleri bul
        const links = embed.querySelectorAll('a');
        links.forEach(link => {
          link.style.pointerEvents = 'auto';
          link.setAttribute('data-turbo', 'false');
        });
      });
    }
  });
}