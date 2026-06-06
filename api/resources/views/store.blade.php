<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- Primary Meta Tags -->
    <title>{{ $store->name }} - 3alamati</title>
    <meta name="title" content="{{ $store->name }} - 3alamati">
    <meta name="description"
        content="{{ $store->description ? Str::limit($store->description, 160) : 'Discover ' . $store->name . ' on 3alamati - Your local business directory' }}">

    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="business.business">
    <meta property="og:url" content="{{ url('/store/' . $store->slug) }}">
    <meta property="og:title" content="{{ $store->name }}">
    <meta property="og:description"
        content="{{ $store->description ? Str::limit($store->description, 200) : 'Discover ' . $store->name . ' on 3alamati' }}">
    <meta property="og:image"
        content="{{ $store->profile_image ?: ($store->cover_image ?: asset('images/default-store.png')) }}">
    <meta property="og:site_name" content="3alamati">

    <!-- Twitter -->
    <meta property="twitter:card" content="summary_large_image">
    <meta property="twitter:url" content="{{ url('/store/' . $store->slug) }}">
    <meta property="twitter:title" content="{{ $store->name }}">
    <meta property="twitter:description"
        content="{{ $store->description ? Str::limit($store->description, 200) : 'Discover ' . $store->name . ' on 3alamati' }}">
    <meta property="twitter:image"
        content="{{ $store->profile_image ?: ($store->cover_image ?: asset('images/default-store.png')) }}">

    <!-- Business specific -->
    @if($store->city || $store->state)
        <meta property="business:contact_data:locality" content="{{ $store->city }}">
        <meta property="business:contact_data:region" content="{{ $store->state }}">
    @endif
    @if($store->phone)
        <meta property="business:contact_data:phone_number" content="{{ $store->phone }}">
    @endif
    @if($store->email)
        <meta property="business:contact_data:email" content="{{ $store->email }}">
    @endif
    @if($store->website)
        <meta property="business:contact_data:website" content="{{ $store->website }}">
    @endif

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

        .cover {
            height: 150px;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            background-size: cover;
            background-position: center;
            position: relative;
        }

        .profile {
            width: 100px;
            height: 100px;
            border-radius: 50%;
            border: 4px solid white;
            position: absolute;
            bottom: -50px;
            left: 50%;
            transform: translateX(-50%);
            background: #eee;
            background-size: cover;
            background-position: center;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
        }

        .content {
            padding: 60px 24px 24px;
            text-align: center;
        }

        h1 {
            font-size: 1.5rem;
            color: #1a1a2e;
            margin-bottom: 8px;
        }

        .category {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            margin-bottom: 12px;
        }

        .description {
            color: #666;
            font-size: 0.95rem;
            line-height: 1.5;
            margin-bottom: 20px;
        }

        .location {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            color: #888;
            font-size: 0.9rem;
            margin-bottom: 20px;
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
        <div class="cover" @if($store->cover_image) style="background-image: url('{{ $store->cover_image }}')" @endif>
            <div class="profile" @if($store->profile_image) style="background-image: url('{{ $store->profile_image }}')"
            @endif></div>
        </div>
        <div class="content">
            <h1>{{ $store->name }}</h1>
            @if($store->category)
                <span class="category">{{ $store->category }}</span>
            @endif
            @if($store->description)
                <p class="description">{{ Str::limit($store->description, 150) }}</p>
            @endif
            @if($store->city || $store->state)
                <div class="location">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                        <circle cx="12" cy="10" r="3"></circle>
                    </svg>
                    {{ collect([$store->city, $store->state])->filter()->implode(', ') }}
                </div>
            @endif
            <a href="https://3alamati.com/store/{{ $store->slug }}" class="cta">View in App</a>
            <p class="app-badge">Powered by 3alamati</p>
        </div>
    </div>
</body>

</html>