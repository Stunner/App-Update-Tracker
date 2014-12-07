
Pod::Spec.new do |s|

  s.name         = "App-Update-Tracker"
  s.version      = "1.0.0"
  s.summary      = "AppUpdateTracker is a simple, lightweight iOS library intended to determine basic app install/update behavior."

  s.description  =  <<-DESC
                   This library allows you to easily determine when the user uses your app after a fresh install, when the user updates your app (and the version from which (s)he updated, and how many times the user has opened a given version of your app. This library was created in order to help determine update information so that appropriate data migration logic could be run after an app update.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC

  s.homepage     = "https://github.com/Stunner/App-Update-Tracker"
  s.license      = { :type => "MIT", :file => "LICENSE.txt" }
  s.author             = { "Stunner" => "ajjubbal@ucdavis.edu" }
  s.social_media_url   = "http://twitter.com/ajubbal"
  s.platform     = :ios
  s.source       = { :git => "https://github.com/Stunner/App-Update-Tracker.git", :tag => "1.0.0" }

  s.source_files  = "AppUpdateTracker"
  s.requires_arc = true

end
