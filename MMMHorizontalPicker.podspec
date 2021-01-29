#
# MMMHorizontalPicker. Part of MMMTemple.
# Copyright (C) 2015-2021 MediaMonks. All rights reserved.
#

Pod::Spec.new do |s|

	s.name = "MMMHorizontalPicker"
	s.version = "1.0"
	s.summary = "Horizontal centering pickerview that supports auto-layout & different item sizes."
	s.description = s.summary
	s.homepage = "https://github.com/mediamonks/#{s.name}"
	s.license = "MIT"
	s.authors = "MediaMonks"
	s.source = { :git => "https://github.com/mediamonks/#{s.name}.git", :tag => s.version.to_s }

	s.ios.deployment_target = '11.0'

	s.subspec 'ObjC' do |ss|		
		ss.source_files = [ "Sources/*.{h,m}" ]
		ss.dependency 'MMMCommonUI/ObjC'
	end
	
	s.swift_versions = '4.2'
	s.static_framework = true	
	s.pod_target_xcconfig = {
		"DEFINES_MODULE" => "YES"
	}

	s.default_subspec = 'ObjC'
end
