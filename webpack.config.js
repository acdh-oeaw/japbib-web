const path = require('path');
const webpack = require("webpack");

module.exports = {
  mode: "production", // "production" | "development" | "none"
  // Chosen mode tells webpack to use its built-in optimizations accordingly.
  entry: {
      main: "./jb_assets.js"
  },
  output: {
    // options related to how webpack emits results
    path: path.resolve(__dirname, 'bower_components'), // string
    // the target directory for all output files
    // must be an absolute path (use the Node.js path module)
    filename: "bundle.js", // string
    // the filename template for entry chunks
    publicPath: "bower_components/", // string
  },
  module:{
    rules: [
      { test: /\.css$/, use: ['style-loader', 'css-loader']},
      { test: /\.(woff|woff2|eot|ttf|otf)$/, use: {loader: 'url-loader', options: {limit: 204800}}},
      { test: /\.(png|svg|jpg|gif)$/, use: {loader: 'url-loader', options: {limit: 204800}}}     
    ]
  },
  performance: {
    hints: "warning", // enum
    maxAssetSize: 204800, // int (in bytes),
    maxEntrypointSize: 800000, // int (in bytes)
    assetFilter: function(assetFilename) {
      // Function predicate that provides asset filenames
      return assetFilename.endsWith('.css') || assetFilename.endsWith('.js');
    }
  },
  devtool: "source-map", // enum
  // enhance debugging by adding meta info for the browser devtools
  // source-map most detailed at the expense of build speed.
  context: __dirname, // string (absolute path!)
  // the home directory for webpack
  // the entry and module.rules.loader option
  //   is resolved relative to this directory
  target: "web", // enum
  // the environment in which the bundle should run
  // changes chunk loading behavior and available modules
  stats: "errors-only",
  plugins: [
      new webpack.ProvidePlugin({
        $: './bower_components/jquery/dist/jquery.min.js',
        jQuery: './bower_components/jquery/dist/jquery.min.js',
        CodeMirror: './bower_components/codemirror/lib/codemirror.js',
        hasher: './bower_components/hasher/dist/js/hasher.min.js',
        crossroads: './bower_components/crossroads/dist/crossroads.min.js',
        URI: './bower_components/urijs/src/URI.min.js',
        Cookies: './bower_components/js-cookie/src/js.cookie.js',
      })
  ]
}