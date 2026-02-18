//
//  ContentView.swift
//  DemoApp
//
//  Clinic demo showcasing the VoiceChatView widget
//

import SwiftUI
import VoiceStreamSDK

struct ContentView: View {

    var body: some View {
        ZStack {
            // Clinic mockup background
            clinicBackground

            // Voice Chat Widget — one-liner with LLM delegation
            if #available(iOS 15.0, *) {
                VoiceChatView(
                    serverUrl: "ws://192.168.1.180:8080/ws",
                    tenantId: "clinic"
                ) { question, respond in
                    // Demo placeholder — in production, call your own LLM here
                    print("[DemoApp] LLM question: \(question)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        respond("This is a demo response for: \"\(question)\". In production, your LLM provides the real answer.")
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Clinic Background

    private var clinicBackground: some View {
        ScrollView {
            VStack(spacing: 0) {
                clinicHeader
                VStack(spacing: 16) {
                    welcomeBanner
                    quickActionsGrid
                    appointmentsSection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .background(Color(hex: "F0F4F8"))
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Header

    private var clinicHeader: some View {
        VStack(spacing: 4) {
            Spacer().frame(height: 50)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MediCare")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("Your Health, Our Priority")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                // Profile icon
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "1E3A5F"), Color(hex: "2E5D8A"), Color(hex: "4A90C4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Welcome Banner

    private var welcomeBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome back!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "1E3A5F"))
                Text("How are you feeling today? Our AI assistant is here to help with appointments and health queries.")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(3)
            }
            Spacer()
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "4A90C4").opacity(0.3))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Quick Actions

    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "1E3A5F"))

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                QuickActionCard(
                    icon: "calendar.badge.plus",
                    title: "Book\nAppointment",
                    color: Color(hex: "4A90C4")
                )
                QuickActionCard(
                    icon: "stethoscope",
                    title: "Find\nDoctor",
                    color: Color(hex: "5BA88C")
                )
                QuickActionCard(
                    icon: "doc.text.magnifyingglass",
                    title: "Lab\nResults",
                    color: Color(hex: "E8945A")
                )
                QuickActionCard(
                    icon: "pills.fill",
                    title: "My\nPrescriptions",
                    color: Color(hex: "9B6DB7")
                )
            }
        }
    }

    // MARK: - Appointments

    private var appointmentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Upcoming Appointments")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "1E3A5F"))
                Spacer()
                Text("See all")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "4A90C4"))
            }

            AppointmentCard(
                doctorName: "Dr. Sarah Ahmed",
                specialty: "General Practitioner",
                date: "Tomorrow",
                time: "10:30 AM",
                iconColor: Color(hex: "4A90C4")
            )

            AppointmentCard(
                doctorName: "Dr. Khalid Mansour",
                specialty: "Cardiologist",
                date: "Wed, Feb 19",
                time: "2:00 PM",
                iconColor: Color(hex: "E8945A")
            )
        }
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "374151"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Appointment Card

struct AppointmentCard: View {
    let doctorName: String
    let specialty: String
    let date: String
    let time: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.fill")
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(doctorName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "1F2937"))
                Text(specialty)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(date)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "1E3A5F"))
                Text(time)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
