Pod::Spec.new do |s|
  s.name         = "HackerSwifter"
  s.version      = "0.1.0"
  s.summary      = "A Hacker News Swift library"
  s.homepage     = "https://github.com/Dimillian/HackerSwifter"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Thomas Ricouard" => "ricouard77@gmail.com" }
  s.source       = { :git => "https://github.com/Dimillian/HackerSwifter.git", :tag => "0.1.0" }
  s.source_files  = "Hacker Swifter/Hacker Swifter/**/*.{h,swift}", "Hacker Swifter/Hacker Swifter/*.{h}"
  s.frameworks   = "Foundation"
  s.requires_arc = true
end