<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- Primary Meta Tags -->
    <title>{{ $store->name }} Products - 3alamati</title>
    <meta name="title" content="{{ $store->name }} Products - 3alamati">
    <meta name="description"
        content="Browse products from {{ $store->name }} on 3alamati - {{ $store->products()->active()->count() }} items available">

    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="{{ url('/store/' . $store->slug . '/products') }}">
    <meta property="og:title" content="{{ $store->name }} - Products & Services">
    <meta property="og:description"
        content="Browse {{ $store->products()->active()->count() }} products from {{ $store->name }} on 3alamati">
    <meta property="og:image"
        content="{{ $store->profile_image ?: ($store->cover_image ?: asset('images/default-store.png')) }}">
    <meta property="og:site_name" content="3alamati">

    <!-- Twitter -->
    <meta property="twitter:card" content="summary_large_image">
    <meta property="twitter:url" content="{{ url('/store/' . $store->slug . '/products') }}">
    <meta property="twitter:title" content="{{ $store->name }} - Products & Services">
    <meta property="twitter:description"
        content="Browse {{ $store->products()->active()->count() }} products from {{ $store->name }} on 3alamati">
    <meta property="twitter:image"
        content="{{ $store->profile_image ?: ($store->cover_image ?: asset('images/default-store.png')) }}">

    <!-- Favicon -->
    <link rel="icon" type="image/png" href="/favicon.png">

    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .card {
            background: white;
            border-radius: 20px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
            max-width: 400px;
            width: 100%;
            overflow: hidden;
        }

        .header {
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            padding: 24px;
            text-align: center;
            color: white;
        }

        .profile {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            border: 3px solid white;
            margin: 0 auto 12px;
            background: #eee;
            background-size: cover;
            background-position: center;
        }

        .store-name {
            font-size: 1.3rem;
            font-weight: 600;
            margin-bottom: 4px;
        }

        .product-count {
            font-size: 0.9rem;
            opacity: 0.9;
        }

        .content {
            padding: 24px;
            text-align: center;
        }

        .icon {
            font-size: 48px;
            margin-bottom: 16px;
        }

        h2 {
            font-size: 1.2rem;
            color: #1a1a2e;
            margin-bottom: 8px;
        }

        .description {
            color: #666;
            font-size: 0.95rem;
            line-height: 1.5;
            margin-bottom: 24px;
        }

        .cta {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            padding: 14px 32px;
            border-radius: 30px;
            font-weight: 600;
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .cta:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(102, 126, 234, 0.4);
        }

        .app-badge {
            margin-top: 16px;
            color: #888;
            font-size: 0.85rem;
        }
    </style>
</head>

<body>
    <div class="card">
        <div class="header">
            <div class="profile" @if($store->profile_image) style="background-image: url('{{ $store->profile_image }}')"
            @endif></div>
            <div class="store-name">{{ $store->name }}</div>
            <div class="product-count">{{ $store->products()->active()->count() }} Products & Services</div>
        </div>
        <div class="content">
            <div class="icon">🛍️</div>
            <h2>Browse Our Collection</h2>
            <p class="description">Discover all products and services from {{ $store->name }}. Open in the 3alamati app
                for the best experience with search, filters, and more.</p>
            <a href="https://3alamati.com/store/{{ $store->slug }}/products" class="cta">Open in App</a>
            <p class="app-badge">Powered by 3alamati</p>
        </div>
    </div>
</body>

</html>