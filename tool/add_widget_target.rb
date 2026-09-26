# Fügt dem Xcode-Projekt das Startbildschirm-Widget (WidgetKit-Erweiterung)
# hinzu. Einmalig; läuft ein zweites Mal ohne Änderungen durch.
#
#   GEM_HOME=$(brew --prefix cocoapods)/libexec ruby tool/add_widget_target.rb
require 'xcodeproj'

NAME = 'RedewendixWidget'
BUNDLE_ID = 'bq.p526.rede.RedewendixWidget'

project = Xcodeproj::Project.open(File.join(__dir__, '..', 'ios', 'Runner.xcodeproj'))
runner = project.targets.find { |t| t.name == 'Runner' }

# Runner: App Group
runner.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end
runner_group = project.main_group.find_subpath('Runner')
unless runner_group.files.any? { |f| f.path == 'Runner.entitlements' }
  runner_group.new_file('Runner.entitlements')
end

if project.targets.any? { |t| t.name == NAME }
  project.save
  puts "#{NAME} existiert bereits."
  exit
end

widget = project.new_target(:app_extension, NAME, :ios, '14.0')
widget.product_reference.name = "#{NAME}.appex"

group = project.main_group.new_group(NAME, NAME)
widget.add_file_references([group.new_file('RedewendixWidget.swift')])
widget.add_resources([group.new_file('Assets.xcassets')])
group.new_file('Info.plist')
group.new_file('RedewendixWidget.entitlements')
xcconfig = group.new_file('RedewendixWidget.xcconfig')

%w[WidgetKit SwiftUI].each do |fw|
  ref = project.frameworks_group.new_file("System/Library/Frameworks/#{fw}.framework", :sdk_root)
  widget.frameworks_build_phase.add_file_reference(ref)
end

widget.build_configurations.each do |c|
  s = c.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = "#{NAME}/Info.plist"
  s['CODE_SIGN_ENTITLEMENTS'] = "#{NAME}/#{NAME}.entitlements"
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['DEVELOPMENT_TEAM'] = runner.build_configurations.first.build_settings['DEVELOPMENT_TEAM'] || ''
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
  s['ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME'] = 'WidgetBackground'
  s['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  s['SKIP_INSTALL'] = 'YES'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  # Versionsnummern aus Flutter (pubspec.yaml) übernehmen.
  c.base_configuration_reference = xcconfig
end

# In die App einbetten. Die Phase muss vor Flutters „Thin Binary“ stehen,
# sonst meldet Xcode einen Zyklus.
runner.add_dependency(widget)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
build_file = embed.add_file_reference(widget.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
runner.build_phases.delete(embed)
thin = runner.build_phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
runner.build_phases.insert(thin || runner.build_phases.size, embed)

project.save
puts "#{NAME} hinzugefügt."
