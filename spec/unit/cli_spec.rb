require 'spec_helper'
require 'shopify_theme'
require 'shopify_theme/cli'

module ShopifyTheme
  describe "Cli" do

    class CliDouble < Cli
      attr_writer :local_files, :mock_config, :sent_list
      attr_reader :sent_list

      def initialize
        @sent_list = []
        @options = {}
      end

      desc "", ""
      def check(exit_on_failure=false)
      end

      desc "",""
      def config
        @mock_config || super
      end

      desc "",""
      def shop_theme_url
        super
      end

      desc "",""
      def binary_file?(file)
        super
      end

      desc "", ""
      def local_files
        @local_files
      end

      desc "", ""
      def send_asset(asset, quiet=false)
        @sent_list << asset
      end
    end

    before do
      @cli = CliDouble.new
      ShopifyTheme.config = {}
    end

    it "should remove assets that are not a part of the white list" do
      @cli.local_files = ['assets/image.png', 'config.yml', 'layout/theme.liquid', 'locales/en.default.json']
      assert_equal 3, @cli.local_assets_list.length
      assert_equal false, @cli.local_assets_list.include?('config.yml')
    end

    it 'should only use the whitelist entries for determining which files to upload (bug #156)' do
      @cli.local_files = %w(assets/application.css.liquid assets/application.js assets/image.png assets/bunny.jpg layout/index.liquid snippets/preview.liquid)
      ShopifyTheme.config = {whitelist_files: %w(assets/application.css.liquid assets/application.js layout/ snippets/)}
      assert_equal 4, @cli.local_assets_list.length
      assert_equal false, @cli.local_assets_list.include?('assets/image.png')
    end

    it "should remove assets that are part of the ignore list" do
      ShopifyTheme.config = {ignore_files: ['config/settings.html']}
      @cli.local_files = ['assets/image.png', 'layout/theme.liquid', 'config/settings.html']
      assert_equal 2, @cli.local_assets_list.length
      assert_equal false, @cli.local_assets_list.include?('config/settings.html')
    end

    it "should generate the shop path URL to the query parameter preview_theme_id if the id is present" do
      @cli.mock_config = {store: 'somethingfancy.myshopify.com', theme_id: 12345}
      assert_equal "somethingfancy.myshopify.com?preview_theme_id=12345", @cli.shop_theme_url
    end

    it "should generate the shop path URL withouth the preview_theme_id if the id is not present" do
      @cli.mock_config = {store: 'somethingfancy.myshopify.com'}
      assert_equal "somethingfancy.myshopify.com", @cli.shop_theme_url

      @cli.mock_config = {store: 'somethingfancy.myshopify.com', theme_id: ''}
      assert_equal "somethingfancy.myshopify.com", @cli.shop_theme_url
    end

    it "should report binary files as such" do
      extensions = %w(png gif jpg jpeg eot svg ttf woff otf swf ico pdf)
      extensions.each do |ext|
        assert @cli.binary_file?("hello.#{ext}"), "#{ext.upcase}s are binary files"
      end
    end

    it "should report unknown files as binary files" do
      assert @cli.binary_file?('omg.wut'), "Unknown filetypes are assumed to be binary"
    end

    it "should not report text based files as binary" do
      refute @cli.binary_file?('theme.liquid'), "liquid files are not binary"
      refute @cli.binary_file?('style.sass.liquid'), "sass.liquid files are not binary"
      refute @cli.binary_file?('style.css'), 'CSS files are not binary'
      refute @cli.binary_file?('application.js'), 'Javascript files are not binary'
      refute @cli.binary_file?('settings_data.json'), 'JSON files are not binary'
      refute @cli.binary_file?('applicaton.js.map'), 'Javascript Map files are not binary'
    end

    describe "theme upload [FILE]" do
      before do
        ShopifyTheme.config = {
          whitelist_files: ['assets/', 'config/'],
          ignore_files: ['assets/disallow.png']
        }
        @cli.local_files = [
          'assets/allow1.png', 
          'assets/allow2.png', 
          'assets/disallow.png', 
          'config/whitelist.json',
          'layout/other.liquid'
        ]
      end

      describe "when specific FILE" do
        it 'should upload specifc files that are in the whitelist and not in the ignore list' do
          @cli.upload('assets/*')
          assert_equal 2, @cli.sent_list.length
          assert_equal true, @cli.sent_list.include?('assets/allow1.png')
          assert_equal true, @cli.sent_list.include?('assets/allow2.png')
        end

        it 'should not upload files that are not in the whitelist' do
          @cli.upload('layout/*')
          assert_equal 0, @cli.sent_list.length
        end
      end

      describe "when not specific FILE" do
        it 'should upload all files that are in the whitelist and not in the ignore list' do
          @cli.upload()
          assert_equal 3, @cli.sent_list.length
          assert_equal true, @cli.sent_list.include?('assets/allow1.png')
          assert_equal true, @cli.sent_list.include?('assets/allow2.png')
          assert_equal true, @cli.sent_list.include?('config/whitelist.json')
        end
      end
    end

  end
end
