// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
//
// class YouTubeVideoPlayer extends StatefulWidget {
//   final String videoUrl;
//
//   const YouTubeVideoPlayer({super.key, required this.videoUrl});
//
//   @override
//   State<YouTubeVideoPlayer> createState() => _YouTubeVideoPlayerState();
// }
//
// class _YouTubeVideoPlayerState extends State<YouTubeVideoPlayer> {
//   late YoutubePlayerController _controller;
//   late String videoId;
//
//   @override
//   void initState() {
//     super.initState();
//     videoId = YoutubePlayer.convertUrlToId(widget.videoUrl) ?? '';
//     _controller = YoutubePlayerController(
//       initialVideoId: videoId,
//       flags: const YoutubePlayerFlags(
//         autoPlay: false,
//         mute: false,
//         enableCaption: true,
//         forceHD: false,
//         isLive: false,
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   Future<void> _launchYouTube(String id) async {
//     final url = 'https://www.youtube.com/watch?v=$id';
//     if (await canLaunchUrl(Uri.parse(url))) {
//       await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Could not launch YouTube.")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         YoutubePlayer(
//           controller: _controller,
//           showVideoProgressIndicator: true,
//           progressIndicatorColor: Colors.red,
//         ),
//         TextButton.icon(
//           onPressed: () => _launchYouTube(videoId),
//           icon: const Icon(Icons.open_in_new),
//           label: const Text("Open in YouTube"),
//         ),
//         const SizedBox(height: 8),
//       ],
//     );
//   }
// }
