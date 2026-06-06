<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\StoreController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\PortfolioController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\StoreChatController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ProductReviewController;
use App\Http\Controllers\Api\UploadController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\UnitController;
use App\Http\Controllers\Api\LocationController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public routes
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

// Categories (public read)
Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/categories/{type}', [CategoryController::class, 'byType'])->where('type', 'store|product|service');

// Units (public read)
Route::get('/units', [UnitController::class, 'index']);

// Locations (public read)
Route::get('/wilayas', [LocationController::class, 'wilayas']);
Route::get('/wilayas/{wilaya}/communes', [LocationController::class, 'communes']);

// Stores (public read)
Route::get('/stores', [StoreController::class, 'index']);
Route::get('/stores/featured', [StoreController::class, 'featured']);
Route::get('/stores/sponsored', [StoreController::class, 'sponsored']);
Route::get('/stores/nearby', [StoreController::class, 'nearby']);
Route::get('/stores/categories', [StoreController::class, 'categories']);
Route::get('/stores/cities', [StoreController::class, 'cities']);
Route::get('/stores/{store}', [StoreController::class, 'show']);

// Products (public read)
Route::get('/stores/{store}/products', [ProductController::class, 'index']);
Route::get('/products/{product}', [ProductController::class, 'show']);

// Home page products & services (public)
Route::get('/products/all/list', [ProductController::class, 'allProducts']);
Route::get('/services/all/list', [ProductController::class, 'allServices']);
Route::get('/products/trending/list', [ProductController::class, 'trendingProducts']);
Route::get('/services/trending/list', [ProductController::class, 'trendingServices']);

// Product Reviews (public read)
Route::get('/products/{product}/reviews', [ProductReviewController::class, 'index']);

// Portfolio (public read)
Route::get('/stores/{store}/portfolio', [PortfolioController::class, 'index']);

// Reviews (public read)
Route::get('/stores/{store}/reviews', [ReviewController::class, 'index']);

// Store Sections (public read)
Route::get('/stores/{store}/sections', [\App\Http\Controllers\Api\StoreSectionController::class, 'index']);
Route::get('/stores/{store}/sections/types', [\App\Http\Controllers\Api\StoreSectionController::class, 'types']);

// ========== SUBSCRIPTIONS ==========
Route::get('/subscriptions/plans', [\App\Http\Controllers\Api\SubscriptionController::class, 'plans']);

// Sponsored Banners (public read)
Route::get('/banners', [\App\Http\Controllers\Api\SponsoredBannerController::class, 'index']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::put('/auth/profile', [AuthController::class, 'updateProfile']);
    Route::put('/auth/change-password', [AuthController::class, 'changePassword']);
    Route::post('/auth/impersonate/{user}', [AuthController::class, 'impersonate']);
    Route::post('/auth/stop-impersonation', [AuthController::class, 'stopImpersonation']);

    // File Uploads
    Route::post('/upload/profile-pic', [UploadController::class, 'profilePic']);
    Route::post('/upload', [UploadController::class, 'store']);

    // Stores (CRUD)
    Route::post('/stores', [StoreController::class, 'store']);
    Route::put('/stores/{store}', [StoreController::class, 'update']);
    Route::delete('/stores/{store}', [StoreController::class, 'destroy']);
    Route::get('/my-stores', [StoreController::class, 'myStores']);

    // Store follow routes
    Route::post('/stores/{store}/follow', [StoreController::class, 'toggleFollow']);
    Route::get('/stores/{store}/followers', [StoreController::class, 'followers']);
    Route::get('/users/followed/stores', [StoreController::class, 'followedStores']);

    // Products (CRUD)
    Route::post('/stores/{store}/products', [ProductController::class, 'store']);
    Route::put('/products/{product}', [ProductController::class, 'update']);
    Route::delete('/products/{product}', [ProductController::class, 'destroy']);

    // Product Reviews
    Route::post('/products/{product}/reviews', [ProductReviewController::class, 'store']);
    Route::put('/product-reviews/{review}', [ProductReviewController::class, 'update']);
    Route::delete('/product-reviews/{review}', [ProductReviewController::class, 'destroy']);

    // Orders
    Route::get('/orders', [OrderController::class, 'myOrders']);
    Route::get('/orders/{order}', [OrderController::class, 'show']);
    Route::post('/orders', [OrderController::class, 'store']);
    Route::get('/store-orders', [OrderController::class, 'storeOrders']);
    Route::put('/orders/{order}/status', [OrderController::class, 'updateStatus']);
    Route::get('/store-orders/stats', [OrderController::class, 'storeStats']);

    // Cart
    Route::get('/cart', [\App\Http\Controllers\Api\CartController::class, 'show']);
    Route::post('/cart/items', [\App\Http\Controllers\Api\CartController::class, 'addItem']);
    Route::put('/cart/items/{item}', [\App\Http\Controllers\Api\CartController::class, 'updateItem']);
    Route::delete('/cart/items/{item}', [\App\Http\Controllers\Api\CartController::class, 'removeItem']);
    Route::delete('/cart', [\App\Http\Controllers\Api\CartController::class, 'clear']);

    // Portfolio (CRUD)
    Route::post('/portfolio', [PortfolioController::class, 'store']);
    Route::put('/portfolio/{portfolioItem}', [PortfolioController::class, 'update']);
    Route::delete('/portfolio/{portfolioItem}', [PortfolioController::class, 'destroy']);

    // Reviews
    Route::post('/stores/{store}/reviews', [ReviewController::class, 'store']);
    Route::delete('/reviews/{review}', [ReviewController::class, 'destroy']);

    // Store Sections (CRUD)
    Route::post('/stores/{store}/sections', [\App\Http\Controllers\Api\StoreSectionController::class, 'store']);
    Route::put('/stores/{store}/sections/{section}', [\App\Http\Controllers\Api\StoreSectionController::class, 'update']);
    Route::delete('/stores/{store}/sections/{section}', [\App\Http\Controllers\Api\StoreSectionController::class, 'destroy']);
    Route::post('/stores/{store}/sections/reorder', [\App\Http\Controllers\Api\StoreSectionController::class, 'reorder']);

    // Users
    Route::get('/users', [UserController::class, 'index']);
    Route::get('/users/{user}', [UserController::class, 'show']);
    Route::put('/users/profile', [UserController::class, 'updateProfile']);
    Route::put('/users/{user}/role', [UserController::class, 'updateRole']);
    Route::delete('/users/{user}', [UserController::class, 'destroy']);
    Route::get('/users/saved/stores', [UserController::class, 'savedStores']);
    Route::post('/users/save-store/{store}', [UserController::class, 'toggleSaveStore']);
    Route::get('/users/connections/list', [UserController::class, 'connections']);
    Route::get('/users/connections/suggestions', [UserController::class, 'connectionSuggestions']);
    Route::post('/users/connections/{user}', [UserController::class, 'sendConnectionRequest']);
    Route::put('/users/connections/{connection}', [UserController::class, 'handleConnectionRequest']);
    Route::get('/users/admin/stats', [UserController::class, 'adminStats']);

    // Chat
    Route::get('/chat/conversations', [ChatController::class, 'conversations']);
    Route::get('/chat/messages/{otherUserId}', [ChatController::class, 'messages']);
    Route::post('/chat/messages', [ChatController::class, 'sendMessage']);
    Route::get('/chat/unread-count', [ChatController::class, 'unreadCount']);
    Route::post('/chat/mark-read/{otherUserId}', [ChatController::class, 'markRead']);
    Route::post('/chat/typing', [ChatController::class, 'typing']);

    // Store Chat (dedicated store inbox)
    Route::get('/stores/{store}/chat/conversations', [StoreChatController::class, 'conversations']);
    Route::get('/stores/{store}/chat/messages/{customerId}', [StoreChatController::class, 'messages']);
    Route::post('/stores/{store}/chat/send', [StoreChatController::class, 'sendMessage']);
    Route::post('/stores/{store}/chat/mark-read/{customerId}', [StoreChatController::class, 'markRead']);
    Route::get('/stores/{store}/chat/unread-count', [StoreChatController::class, 'unreadCount']);

    // Notifications
    Route::get('/notifications', [\App\Http\Controllers\Api\NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [\App\Http\Controllers\Api\NotificationController::class, 'unreadCount']);
    Route::post('/notifications/{id}/read', [\App\Http\Controllers\Api\NotificationController::class, 'markAsRead']);
    Route::post('/notifications/read-all', [\App\Http\Controllers\Api\NotificationController::class, 'markAllAsRead']);
    Route::delete('/notifications/{id}', [\App\Http\Controllers\Api\NotificationController::class, 'destroy']);

    // Employees (store owner manages their employees)
    Route::get('/employees', [\App\Http\Controllers\Api\EmployeeController::class, 'index']);
    Route::post('/employees', [\App\Http\Controllers\Api\EmployeeController::class, 'store']);
    Route::put('/employees/{employee}', [\App\Http\Controllers\Api\EmployeeController::class, 'update']);
    Route::delete('/employees/{employee}', [\App\Http\Controllers\Api\EmployeeController::class, 'destroy']);
    Route::get('/employees/permissions', [\App\Http\Controllers\Api\EmployeeController::class, 'permissions']);
    Route::get('/employees/my-stores', [\App\Http\Controllers\Api\EmployeeController::class, 'myStoresAsEmployee']);

    // Broadcasting auth for WebSocket
    Route::post('/broadcasting/auth', function (\Illuminate\Http\Request $request) {
        return \Illuminate\Support\Facades\Broadcast::auth($request);
    });

    // Admin Featured Items Management
    Route::get('/admin/featured', [ProductController::class, 'getFeatured']);
    Route::post('/admin/featured', [ProductController::class, 'addFeatured']);
    Route::delete('/admin/featured/{featuredItem}', [ProductController::class, 'removeFeatured']);
    Route::put('/admin/featured/order', [ProductController::class, 'updateFeaturedOrder']);


    Route::get('/subscriptions/my', [\App\Http\Controllers\Api\SubscriptionController::class, 'mySubscription']);
    Route::post('/subscriptions/subscribe', [\App\Http\Controllers\Api\SubscriptionController::class, 'subscribe']);
    Route::post('/subscriptions/upgrade-to-store-owner', [\App\Http\Controllers\Api\SubscriptionController::class, 'upgradeToStoreOwner']);
    Route::get('/subscriptions/limits', [\App\Http\Controllers\Api\SubscriptionController::class, 'checkLimits']);

    // Admin Subscription Management
    Route::get('/admin/subscriptions', [\App\Http\Controllers\Api\AdminSubscriptionController::class, 'index']);
    Route::get('/admin/subscriptions/stats', [\App\Http\Controllers\Api\AdminSubscriptionController::class, 'stats']);
    Route::get('/admin/subscriptions/{id}', [\App\Http\Controllers\Api\AdminSubscriptionController::class, 'show']);
    Route::post('/admin/subscriptions/{id}/approve', [\App\Http\Controllers\Api\AdminSubscriptionController::class, 'approve']);
    Route::post('/admin/subscriptions/{id}/reject', [\App\Http\Controllers\Api\AdminSubscriptionController::class, 'reject']);
    Route::post('/admin/stores/{storeId}/validate', [\App\Http\Controllers\Api\AdminSubscriptionController::class, 'validateStore']);
    Route::post('/admin/stores/{storeId}/invalidate', [\App\Http\Controllers\Api\AdminSubscriptionController::class, 'invalidateStore']);

    // Admin Category Management
    Route::post('/admin/categories', [CategoryController::class, 'store']);
    Route::put('/admin/categories/{category}', [CategoryController::class, 'update']);
    Route::delete('/admin/categories/{category}', [CategoryController::class, 'destroy']);
    Route::post('/admin/categories/reorder', [CategoryController::class, 'reorder']);

    Route::post('/admin/units', [UnitController::class, 'store']);
    Route::put('/admin/units/{unit}', [UnitController::class, 'update']);
    Route::delete('/admin/units/{unit}', [UnitController::class, 'destroy']);
    Route::post('/admin/units/reorder', [UnitController::class, 'reorder']);

    // Admin Sponsored Banners Management
    Route::get('/admin/banners', [\App\Http\Controllers\Api\SponsoredBannerController::class, 'adminIndex']);
    Route::post('/admin/banners', [\App\Http\Controllers\Api\SponsoredBannerController::class, 'store']);
    Route::put('/admin/banners/{sponsoredBanner}', [\App\Http\Controllers\Api\SponsoredBannerController::class, 'update']);
    Route::delete('/admin/banners/{sponsoredBanner}', [\App\Http\Controllers\Api\SponsoredBannerController::class, 'destroy']);

    // Admin Subscription Plans Management
    Route::get('/admin/plans', [\App\Http\Controllers\Api\AdminSubscriptionPlanController::class, 'index']);
    Route::post('/admin/plans', [\App\Http\Controllers\Api\AdminSubscriptionPlanController::class, 'store']);
    Route::put('/admin/plans/{plan}', [\App\Http\Controllers\Api\AdminSubscriptionPlanController::class, 'update']);
    Route::delete('/admin/plans/{plan}', [\App\Http\Controllers\Api\AdminSubscriptionPlanController::class, 'destroy']);
    Route::post('/admin/plans/{plan}/toggle-active', [\App\Http\Controllers\Api\AdminSubscriptionPlanController::class, 'toggleActive']);
    Route::post('/admin/plans/reorder', [\App\Http\Controllers\Api\AdminSubscriptionPlanController::class, 'reorder']);

    // Admin Featured Stores Management
    Route::get('/admin/stores/featured', [StoreController::class, 'adminListForFeatured']);
    Route::post('/admin/stores/{store}/toggle-featured', [StoreController::class, 'toggleFeatured']);

    // Admin Sponsored Stores Management
    Route::get('/admin/stores/sponsored', [StoreController::class, 'adminListForSponsored']);
    Route::post('/admin/stores/{store}/toggle-sponsored', [StoreController::class, 'toggleSponsored']);

    // Import
    Route::post('/admin/import/stores', [\App\Http\Controllers\Api\ImportController::class, 'store']);
});

// ========== DEMANDS (Job Requests) ==========
// Public routes
Route::get('/demands', [\App\Http\Controllers\Api\DemandController::class, 'index']);
Route::get('/demands/{id}', [\App\Http\Controllers\Api\DemandController::class, 'show']);
Route::get('/demands/{id}/offers', [\App\Http\Controllers\Api\DemandOfferController::class, 'index']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/demands', [\App\Http\Controllers\Api\DemandController::class, 'store']);
    Route::put('/demands/{id}', [\App\Http\Controllers\Api\DemandController::class, 'update']);
    Route::delete('/demands/{id}', [\App\Http\Controllers\Api\DemandController::class, 'destroy']);
    Route::get('/demands/user/my', [\App\Http\Controllers\Api\DemandController::class, 'myDemands']);
    Route::put('/demands/{id}/close', [\App\Http\Controllers\Api\DemandController::class, 'close']);
    Route::put('/demands/{id}/complete', [\App\Http\Controllers\Api\DemandController::class, 'complete']);
    Route::put('/demands/{id}/cancel', [\App\Http\Controllers\Api\DemandController::class, 'cancel']);

    // Offers
    Route::post('/demands/{id}/offers', [\App\Http\Controllers\Api\DemandOfferController::class, 'store']);
    Route::put('/offers/{id}', [\App\Http\Controllers\Api\DemandOfferController::class, 'update']);
    Route::delete('/offers/{id}', [\App\Http\Controllers\Api\DemandOfferController::class, 'destroy']);
    Route::put('/offers/{id}/accept', [\App\Http\Controllers\Api\DemandOfferController::class, 'accept']);
    Route::put('/offers/{id}/reject', [\App\Http\Controllers\Api\DemandOfferController::class, 'reject']);
    Route::get('/offers/my', [\App\Http\Controllers\Api\DemandOfferController::class, 'myOffers']);
});

// API Info
Route::get('/', function () {
    return response()->json([
        'name' => '3alamati API',
        'version' => '1.0.0',
        'framework' => 'Laravel',
    ]);
});

