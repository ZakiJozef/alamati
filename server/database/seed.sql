-- 3alamati Seed Data
USE `3alamati`;

-- Seed Users (password is 'password123' for all users)
-- bcrypt hash of 'password123'
INSERT INTO users (username, email, password_hash, profile_pic, role, pseudoname) VALUES
('admin', 'admin@3alamati.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'https://ui-avatars.com/api/?name=Admin&background=137fec&color=fff', 'super_admin', 'Super Admin'),
('john_cafe', 'owner@coffeeshop.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'https://ui-avatars.com/api/?name=John+Doe&background=22c55e&color=fff', 'store_owner', 'John Doe'),
('jane_user', 'user@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'https://ui-avatars.com/api/?name=Jane+Smith&background=f59e0b&color=fff', 'visitor', 'Jane Smith');

-- Seed Stores
INSERT INTO stores (owner_id, name, description, cover_image, profile_image, address, city, state, category, phone, phones, email, website, lat, lng, rating, review_count, is_open, is_featured, is_sponsored, social_links) VALUES
(2, 'Bean & Brew Cafe', 'Taste the finest roasted coffee in the city. Crafting the perfect cup since 2015.', 
 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800', 
 'https://images.unsplash.com/photo-1559305616-3f99cd43e353?w=400',
 '123 Coffee Lane', 'New York', 'NY', 'Food & Beverage',
 '+1 (555) 123-4567', '[\"+1 (555) 123-4567\", \"+1 (555) 123-4568\"]',
 'hello@beanandbrew.com', 'https://beanandbrew.com',
 40.7128, -74.0060, 4.9, 120, TRUE, TRUE, TRUE,
 '{\"facebook\": \"beanandbrew\", \"instagram\": \"beanandbrew\", \"whatsapp\": \"+15551234567\", \"tiktok\": \"beanandbrew\"}'),

(2, 'FixIt Auto Repair', 'Your trusted auto repair shop. Quality service at affordable prices.',
 'https://images.unsplash.com/photo-1487754180451-c456f719a1fc?w=800',
 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=400',
 '456 Mechanic Ave', 'New York', 'NY', 'Automotive',
 '+1 (555) 234-5678', '[\"+1 (555) 234-5678\"]',
 'service@fixitauto.com', 'https://fixitauto.com',
 40.7580, -73.9855, 4.5, 85, FALSE, TRUE, FALSE,
 '{\"facebook\": \"fixitauto\", \"instagram\": \"fixitautorepair\"}'),

(2, 'Pixel Perfect Studio', 'Creative design studio specializing in branding, UI/UX, and digital experiences.',
 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
 'https://images.unsplash.com/photo-1560179707-f14e90ef3623?w=400',
 '789 Design Blvd', 'New York', 'NY', 'Creative',
 '+1 (555) 345-6789', '[\"+1 (555) 345-6789\"]',
 'hello@pixelperfect.studio', 'https://pixelperfect.studio',
 40.7489, -73.9680, 5.0, 42, TRUE, TRUE, TRUE,
 '{\"facebook\": \"pixelperfectstudio\", \"instagram\": \"pixelperfect\", \"linkedin\": \"pixel-perfect-studio\", \"youtube\": \"pixelperfectstudio\"}'),

(2, 'Urban Cuts', 'Premium barbershop experience. Modern cuts, classic style.',
 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=800',
 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400',
 '321 Style Street', 'Brooklyn', 'NY', 'Hair & Beauty',
 '+1 (555) 456-7890', '[\"+1 (555) 456-7890\"]',
 'book@urbancuts.com', 'https://urbancuts.com',
 40.6782, -73.9442, 4.8, 98, TRUE, FALSE, FALSE,
 '{\"instagram\": \"urbancuts_nyc\", \"tiktok\": \"urbancuts\"}'),

(2, 'The Knowledge Hub', 'Educational resources and tutoring services for all ages.',
 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800',
 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?w=400',
 '555 Learning Lane', 'Manhattan', 'NY', 'Education',
 '+1 (555) 567-8901', '[\"+1 (555) 567-8901\"]',
 'learn@knowledgehub.edu', 'https://knowledgehub.edu',
 40.7831, -73.9712, 4.8, 65, TRUE, FALSE, FALSE,
 '{\"facebook\": \"theknowledgehub\", \"linkedin\": \"the-knowledge-hub\"}'),

(2, 'WellCare Clinic', 'Comprehensive healthcare services with a personal touch.',
 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800',
 'https://images.unsplash.com/photo-1538108149393-fbbd81895907?w=400',
 '999 Health Avenue', 'Queens', 'NY', 'Health',
 '+1 (555) 678-9012', '[\"+1 (555) 678-9012\", \"+1 (555) 678-9013\"]',
 'care@wellcareclinic.com', 'https://wellcareclinic.com',
 40.7282, -73.7949, 4.6, 75, TRUE, FALSE, FALSE,
 '{\"facebook\": \"wellcareclinic\", \"instagram\": \"wellcare_clinic\"}');

-- Seed Portfolio Items for Pixel Perfect Studio (store_id = 3)
INSERT INTO portfolio_items (store_id, title, description, image) VALUES
(3, 'Modern Workspace', 'Interior Design: A minimalist approach for optimal productivity and aesthetic appeal.', 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=600'),
(3, 'Fintech Mobile App', 'UI/UX Project: Redefining digital banking with intuitive design and seamless user flows.', 'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=600'),
(3, 'Brand Identity', 'Graphic Design: Developing a cohesive visual language that resonates with the brand core values.', 'https://images.unsplash.com/photo-1558655146-9f40138edfeb?w=600'),
(3, 'E-commerce Website', 'Web Design: Crafting an engaging online shopping experience with a focus on conversion.', 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=600');

-- Seed Products for Bean & Brew Cafe (store_id = 1)
INSERT INTO products (store_id, name, description, price, image, type) VALUES
(1, 'Signature Espresso', 'Our house blend espresso with rich, bold flavor.', 3.50, 'https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?w=400', 'product'),
(1, 'Cappuccino', 'Classic Italian cappuccino with silky foam.', 4.50, 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400', 'product'),
(1, 'Avocado Toast', 'Fresh avocado on artisan bread with seasoning.', 8.00, 'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=400', 'product'),
(1, 'Catering Service', 'Coffee catering for events and meetings.', 150.00, 'https://images.unsplash.com/photo-1511920170033-f8396924c348?w=400', 'service');

-- Seed Reviews
INSERT INTO reviews (store_id, user_id, rating, comment) VALUES
(1, 3, 5, 'Best coffee in the city! The atmosphere is amazing and staff is super friendly.'),
(1, 3, 5, 'Love coming here for my morning espresso. Never disappoints!'),
(3, 3, 5, 'Incredible design work! They completely transformed our brand identity.'),
(4, 3, 4, 'Great haircut, will definitely come back. A bit of a wait though.');

-- Seed Saved Stores
INSERT INTO saved_stores (user_id, store_id) VALUES
(3, 1),
(3, 3),
(3, 4);
