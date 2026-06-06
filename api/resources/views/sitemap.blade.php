<?php echo '<?xml version="1.0" encoding="UTF-8"?>'; ?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    @foreach ($stores as $store)
        <url>
            <loc>https://3alamati.com/store/{{ $store->slug ?? $store->id }}</loc>
            <lastmod>{{ $store->updated_at->toAtomString() }}</lastmod>
            <changefreq>weekly</changefreq>
            <priority>{{ $store->is_featured ? 1.0 : 0.8 }}</priority>
        </url>
    @endforeach

    @foreach ($products as $product)
        @if($product->store)
        <url>
            <loc>https://3alamati.com/product/{{ $product->id }}</loc>
            <lastmod>{{ $product->updated_at->toAtomString() }}</lastmod>
            <changefreq>weekly</changefreq>
            <priority>0.7</priority>
        </url>
        @endif
    @endforeach
</urlset>
